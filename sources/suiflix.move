module suiflix::suiflix {
    use sui::sui::SUI;
    use std::vector;
    use sui::transfer;
    use std::string::String;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    // Struct representing the Platform where users can pay to view movies.
    struct Platform has key, store {
        id: UID,                        // Unique identifier for the Platform
        name: String,                   // Name of the Platform
        balance: Balance<SUI>,          // Balance of SUI tokens held by the Platform
        users: vector<address>,         // List of addresses representing users registered on the Platform
        transactions: Table<ID, ViewingTransaction>, // Table storing all viewing transactions
        movies: Table<ID, Movie>,       // Table storing all movies available on the Platform
        owner: address,                 // Address of the Platform owner
    }

    // Struct representing a User on the Platform.
    struct User has key, store {
        id: UID,                        // Unique identifier for the User
        user: address,                  // Address of the User
        platform_id: ID,                // Identifier of the Platform the User is registered on
        balance: Balance<SUI>,          // Balance of SUI tokens held by the User
        arrears: u64,                   // Outstanding balance or amount the User owes
    }

    // Struct representing a Viewing Transaction on the Platform.
    struct ViewingTransaction has key, store {
        id: UID,                        // Unique identifier for the Viewing Transaction
        user_id: ID,                    // Identifier of the User who made the transaction
        platform_id: ID,                // Identifier of the Platform where the transaction occurred
        amount: u64,                    // Amount of SUI tokens paid for the transaction
        movie_id: u64,                  // Identifier of the Movie viewed
        viewed_date: u64,               // Timestamp when the movie was viewed
    }

    // Struct representing a Movie available on the Platform.
    struct Movie has key, store {
        id: UID,                        // Unique identifier for the Movie
        user_id: ID,                    // Identifier of the User who uploaded the movie
        platform_id: ID,                // Identifier of the Platform where the movie is available
        title: String,                  // Title of the Movie
        amount: u64,                    // Amount of SUI tokens required to view the movie
        added_date: u64,                // Timestamp when the movie was added to the Platform
    }

    // Error codes used for various checks and balances in the module.
    const ENotPlatformOwner: u64 = 0;  // Error code when the action is attempted by a non-owner
    const EInsufficientFunds: u64 = 1; // Error code for insufficient funds in balance
    const EInsufficientBalance: u64 = 2; // Error code for insufficient platform balance

    // Function to create a new Platform.
    public fun add_platform(
        name: String,
        ctx: &mut TxContext
    ) : Platform {
        let id = object::new(ctx);
        Platform {
            id,
            name,
            balance: balance::zero<SUI>(), // Initializing with zero balance
            users: vector::empty<address>(), // Initializing with empty user list
            movies: table::new<ID, Movie>(ctx), // Initializing empty movie table
            transactions: table::new<ID, ViewingTransaction>(ctx), // Initializing empty transaction table
            owner: tx_context::sender(ctx), // Setting the creator as the owner
        }
    }

    // Function to register a new User on the Platform.
    public fun add_user(
        user: address,
        platform: &mut Platform,
        ctx: &mut TxContext
    ) : User {
        let id = object::new(ctx);
        let new_user = User {
            id,
            user,
            platform_id: object::id(platform),
            arrears: 0, // Initializing arrears to zero
            balance: balance::zero<SUI>(), // Initializing balance to zero
        };

        // Adding the user to the Platform's user list
        vector::push_back<address>(&mut platform.users, user);

        new_user
    }

    // Function to add a new movie to the Platform.
    public fun add_movie(
        platform: &mut Platform,
        user: &mut User,
        amount: u64,
        title: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let movie_id = object::new(ctx);
        let movie = Movie {
            id: movie_id,
            user_id: object::id(user),
            platform_id: user.platform_id,
            amount, // Setting the amount required to view the movie
            title,  // Setting the title of the movie
            added_date: clock::timestamp_ms(clock), // Setting the added date to current time
        };

        // Increasing user's arrears by the amount of the movie
        user.arrears = user.arrears + amount;

        // Adding the movie to the Platform's movie table
        table::add<ID, Movie>(&mut platform.movies, object::uid_to_inner(&movie.id), movie);
    }

    // Function to deposit SUI tokens into the User's balance.
    public fun deposit(
        user: &mut User,
        amount: Coin<SUI>,
    ) {
        let coin = coin::into_balance(amount);
        balance::join(&mut user.balance, coin); // Adding the coin balance to user's balance
    }

    // Function for a User to pay to view a movie.
    public fun view_movie(
        platform: &mut Platform,
        user: &mut User,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if the User has enough balance to pay for the movie
        assert!(balance::value(&user.balance) >= amount, EInsufficientFunds);

        // Deduct the amount from the User's balance
        let viewing_amount = coin::take(&mut user.balance, amount, ctx);

        // Transfer the deducted amount to the Platform owner
        transfer::public_transfer(viewing_amount, platform.owner);

        // Create a new viewing transaction
        let transaction_id = object::new(ctx);
        let transaction = ViewingTransaction {
            id: transaction_id,
            user_id: object::id(user),
            platform_id: user.platform_id,
            amount,
            movie_id: 0, // Placeholder for the movie ID (can be updated to actual movie ID)
            viewed_date: clock::timestamp_ms(clock), // Setting the viewed date to current time
        };

        // Add the viewing transaction to the Platform's transaction table
        table::add<ID, ViewingTransaction>(&mut platform.transactions, object::uid_to_inner(&transaction.id), transaction);

        // Decrease the User's arrears by the amount paid
        user.arrears = user.arrears - amount;
    }

    // Function to withdraw SUI tokens from the Platform's balance.
    public fun withdraw(
        platform: &mut Platform,
        amount: u64,
        ctx: &mut TxContext
    ) {
        // Ensure that only the Platform owner can withdraw funds
        assert!(tx_context::sender(ctx) == platform.owner, ENotPlatformOwner);

        // Check if the Platform has sufficient balance for withdrawal
        assert!(balance::value(&platform.balance) >= amount, EInsufficientBalance);

        // Deduct the amount from the Platform's balance
        let withdrawn = coin::take(&mut platform.balance, amount, ctx);

        // Transfer the withdrawn amount to the Platform owner
        transfer::public_transfer(withdrawn, platform.owner);
    }
}
