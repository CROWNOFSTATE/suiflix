module suiflix::suiflix {
    use sui::sui::SUI;
    use std::vector;
    use sui::transfer;
    use std::string::String;
    use sui::coin;
    use sui::clock;
    use sui::object::{self, ID, UID};
    use sui::balance;
    use sui::tx_context::{self, TxContext};
    use sui::table::{self, Table};

    // Struct representing the Platform where users can pay to view movies.
    struct Platform has key, store {
        id: UID,                        
        name: String,                   
        balance: Balance<SUI>,          
        users: vector<address>,         
        transactions: Table<ID, ViewingTransaction>, 
        movies: Table<ID, Movie>,       
        owner: address,                 
    }

    // Struct representing a User on the Platform.
    struct User has key, store {
        id: UID,                        
        address: address,               
        platform_id: ID,                
        balance: Balance<SUI>,          
        outstanding_balance: u64,       
        movies_on_credit: vector<ID>,   // List of movie IDs viewed on credit
    }

    // Struct representing a Viewing Transaction on the Platform.
    struct ViewingTransaction has key, store {
        id: UID,                        
        user_id: ID,                    
        platform_id: ID,                
        amount: u64,                    
        movie_id: ID,                   
        viewed_date: u64,               
    }

    // Struct representing a Movie available on the Platform.
    struct Movie has key, store {
        id: UID,                        
        user_id: ID,                    
        platform_id: ID,                
        title: String,                  
        amount: u64,                    
        added_date: u64,                
    }

    // Error codes used for various checks and balances in the module.
    const ENotPlatformOwner: u64 = 0;  
    const EInsufficientFunds: u64 = 1; 
    const EInsufficientBalance: u64 = 2; 
    const EUserAlreadyExists: u64 = 3;
    const EMovieNotFound: u64 = 4;
    const EUserNotFound: u64 = 5;

    // Function to create a new Platform.
    public fun add_platform(
        name: String,
        ctx: &mut TxContext
    ) : Platform {
        let id = object::new(ctx);
        Platform {
            id,
            name,
            balance: balance::zero<SUI>(),
            users: vector::empty<address>(),
            movies: table::new<ID, Movie>(ctx),
            transactions: table::new<ID, ViewingTransaction>(ctx),
            owner: tx_context::sender(ctx),
        }
    }

    // Function to register a new User on the Platform.
    public fun add_user(
        user_address: address,
        platform: &mut Platform,
        ctx: &mut TxContext
    ) : User {
        let id = object::new(ctx);
        let new_user = User {
            id,
            address: user_address,
            platform_id: object::id(platform),
            outstanding_balance: 0,
            balance: balance::zero<SUI>(),
            movies_on_credit: vector::empty<ID>(),
        };

        // Check if the user already exists
        let user_exists = vector::contains<address>(&platform.users, user_address);
        assert!(!user_exists, EUserAlreadyExists);

        // Adding the user to the Platform's user list
        vector::push_back<address>(&mut platform.users, user_address);

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
            amount,
            title,
            added_date: clock::timestamp_ms(clock),
        };

        // Adding the movie to the Platform's movie table
        table::add<ID, Movie>(&mut platform.movies, object::uid_to_inner(&movie.id), movie);
    }

    // Function to deposit SUI tokens into the User's balance.
    public fun deposit(
        user: &mut User,
        amount: Coin<SUI>,
    ) {
        let coin_balance = coin::into_balance(amount);
        balance::join(&mut user.balance, coin_balance);
    }

    // Function for a User to pay to view a movie.
    public fun view_movie(
        platform: &mut Platform,
        user: &mut User,
        movie_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if the movie exists
        let movie = table::borrow<ID, Movie>(&platform.movies, movie_id);
        assert!(balance::value(&user.balance) >= movie.amount, EInsufficientFunds);

        // Deduct the amount from the User's balance
        let viewing_amount = coin::take(&mut user.balance, movie.amount, ctx);

        // Transfer the deducted amount to the Platform owner
        transfer::public_transfer(viewing_amount, platform.owner);

        // Create a new viewing transaction
        let transaction_id = object::new(ctx);
        let transaction = ViewingTransaction {
            id: transaction_id,
            user_id: object::id(user),
            platform_id: user.platform_id,
            amount: movie.amount,
            movie_id,
            viewed_date: clock::timestamp_ms(clock),
        };

        // Add the viewing transaction to the Platform's transaction table
        table::add<ID, ViewingTransaction>(&mut platform.transactions, object::uid_to_inner(&transaction.id), transaction);

        // Record the movie as viewed on credit
        vector::push_back<ID>(&mut user.movies_on_credit, movie_id);
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
