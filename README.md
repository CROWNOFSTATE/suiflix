# SuiFlix: A Movie Viewing Platform

## Overview

SuiFlix is a movie viewing platform implemented as a Move module, where users can pay to watch movies using SUI tokens. The platform allows for the registration of users, adding movies, handling deposits, viewing transactions, and managing withdrawals.

## Module Structure

### Imports

The module imports necessary functionalities from the SUI standard library, including:
- `sui::sui::SUI`
- `std::vector`
- `sui::transfer`
- `std::string::String`
- `sui::coin::{Self, Coin}`
- `sui::clock::{Self, Clock}`
- `sui::object::{Self, ID, UID}`
- `sui::balance::{Self, Balance}`
- `sui::tx_context::{Self, TxContext}`
- `sui::table::{Self, Table}`

### Structs

1. **Platform**
    - Represents the SuiFlix platform.
    - Attributes:
        - `id`: Unique identifier.
        - `name`: Name of the platform.
        - `balance`: Balance of SUI tokens held by the platform.
        - `users`: List of addresses representing registered users.
        - `transactions`: Table storing all viewing transactions.
        - `movies`: Table storing all available movies.
        - `owner`: Address of the platform owner.

2. **User**
    - Represents a user on the SuiFlix platform.
    - Attributes:
        - `id`: Unique identifier.
        - `user`: Address of the user.
        - `platform_id`: Identifier of the platform the user is registered on.
        - `balance`: Balance of SUI tokens held by the user.
        - `arrears`: Outstanding balance or amount the user owes.

3. **ViewingTransaction**
    - Represents a viewing transaction on the SuiFlix platform.
    - Attributes:
        - `id`: Unique identifier.
        - `user_id`: Identifier of the user who made the transaction.
        - `platform_id`: Identifier of the platform where the transaction occurred.
        - `amount`: Amount of SUI tokens paid for the transaction.
        - `movie_id`: Identifier of the movie viewed.
        - `viewed_date`: Timestamp when the movie was viewed.

4. **Movie**
    - Represents a movie available on the SuiFlix platform.
    - Attributes:
        - `id`: Unique identifier.
        - `user_id`: Identifier of the user who uploaded the movie.
        - `platform_id`: Identifier of the platform where the movie is available.
        - `title`: Title of the movie.
        - `amount`: Amount of SUI tokens required to view the movie.
        - `added_date`: Timestamp when the movie was added to the platform.

### Error Codes

- `ENotPlatformOwner: u64 = 0`: Error code when the action is attempted by a non-owner.
- `EInsufficientFunds: u64 = 1`: Error code for insufficient funds in the user's balance.
- `EInsufficientBalance: u64 = 2`: Error code for insufficient balance in the platform's balance.

### Functions

1. **add_platform**
    - Creates a new SuiFlix platform.
    - Parameters:
        - `name: String`: Name of the platform.
        - `ctx: &mut TxContext`: Transaction context.
    - Returns:
        - `Platform`: The newly created platform.

2. **add_user**
    - Registers a new user on the platform.
    - Parameters:
        - `user: address`: Address of the user.
        - `platform: &mut Platform`: Reference to the platform.
        - `ctx: &mut TxContext`: Transaction context.
    - Returns:
        - `User`: The newly registered user.

3. **add_movie**
    - Adds a new movie to the platform.
    - Parameters:
        - `platform: &mut Platform`: Reference to the platform.
        - `user: &mut User`: Reference to the user.
        - `amount: u64`: Amount of SUI tokens required to view the movie.
        - `title: String`: Title of the movie.
        - `clock: &Clock`: Clock reference for timestamp.
        - `ctx: &mut TxContext`: Transaction context.

4. **deposit**
    - Deposits SUI tokens into the user's balance.
    - Parameters:
        - `user: &mut User`: Reference to the user.
        - `amount: Coin<SUI>`: Amount of SUI tokens to deposit.

5. **view_movie**
    - Allows a user to pay to view a movie.
    - Parameters:
        - `platform: &mut Platform`: Reference to the platform.
        - `user: &mut User`: Reference to the user.
        - `amount: u64`: Amount of SUI tokens to pay for viewing the movie.
        - `clock: &Clock`: Clock reference for timestamp.
        - `ctx: &mut TxContext`: Transaction context.

6. **withdraw**
    - Allows the platform owner to withdraw SUI tokens from the platform's balance.
    - Parameters:
        - `platform: &mut Platform`: Reference to the platform.
        - `amount: u64`: Amount of SUI tokens to withdraw.
        - `ctx: &mut TxContext`: Transaction context.

## Usage

1. **Create Platform**: Use `add_platform` to create a new SuiFlix platform.
2. **Register User**: Use `add_user` to register users on the platform.
3. **Add Movie**: Use `add_movie` to add movies to the platform.
4. **Deposit Tokens**: Users can deposit SUI tokens into their balance using `deposit`.
5. **View Movie**: Users can pay to view movies using `view_movie`.
6. **Withdraw Tokens**: Platform owners can withdraw tokens from the platform using `withdraw`.

By following these steps, users and platform owners can effectively manage and use the SuiFlix platform to facilitate movie viewing transactions.
