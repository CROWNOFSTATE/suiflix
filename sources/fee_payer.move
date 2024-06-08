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

    struct Platform has key, store {
        id: UID,
        name: String,
        balance: Balance<SUI>,
        users: vector<address>,
        transactions: Table<ID, ViewingTransaction>,
        movies: Table<ID, Movie>,
        owner: address,
    }

    struct User has key, store {
        id: UID,
        user: address,
        platform_id: ID,
        balance: Balance<SUI>,
    }

    struct ViewingTransaction has key, store {
        id: UID,
        user_id: ID,
        platform_id: ID,
        amount: u64,
        movie_id: ID,
        viewed_date: u64,
    }

    struct Movie has key, store {
        id: UID,
        user_id: ID,
        platform_id: ID,
        title: String,
        amount: u64,
        added_date: u64,
    }

    const ENotPlatformOwner: u64 = 0;
    const EInsufficientFunds: u64 = 1;
    const EInsufficientBalance: u64 = 2;

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
            balance: balance::zero<SUI>(),
        };

        vector::push_back<address>(&mut platform.users, user);

        new_user
    }

    public fun add_movie(
        platform: &mut Platform,
        user: &mut User,
        amount: u64,
        title: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, EInsufficientFunds); // Added validation for non-zero movie amount

        let movie_id = object::new(ctx);
        let movie = Movie {
            id: movie_id,
            user_id: object::id(user),
            platform_id: user.platform_id,
            amount,
            title,
            added_date: clock::timestamp_ms(clock),
        };

        balance::pay(&mut user.balance, amount, &mut platform.balance); // Deduct movie amount from user's balance

        table::add<ID, Movie>(&mut platform.movies, object::uid_to_inner(&movie.id), movie);
    }

    public fun deposit(
        user: &mut User,
        amount: Coin<SUI>,
    ) {
        let coin = coin::into_balance(amount);
        balance::join(&mut user.balance, coin);
    }

    public fun view_movie(
        platform: &mut Platform,
        user: &mut User,
        movie_id: ID,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&user.balance) >= amount, EInsufficientFunds);

        let viewing_amount = coin::take(&mut user.balance, amount, ctx);
        transfer::public_transfer(viewing_amount, platform.owner);

        let transaction_id = object::new(ctx);
        let transaction = ViewingTransaction {
            id: transaction_id,
            user_id: object::id(user),
            platform_id: user.platform_id,
            amount,
            movie_id, // Use the provided movie_id instead of a placeholder
            viewed_date: clock::timestamp_ms(clock),
        };

        table::add<ID, ViewingTransaction>(&mut platform.transactions, object::uid_to_inner(&transaction.id), transaction);
    }

    public fun withdraw(
        platform: &mut Platform,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == platform.owner, ENotPlatformOwner);

        let balance_value = balance::value(&platform.balance);
        let withdrawn = coin::take(&mut platform.balance, balance_value, ctx);
        transfer::public_transfer(withdrawn, platform.owner);
    }
}
