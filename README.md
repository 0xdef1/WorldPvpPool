## WorldPvpPool

A contract to pool resources and win the presidency in [worldpvp.co](https://worldpvp.co)

    - Deposit a country token into a pool and receive a receipt token (wrapper)
    - With enough deposits, the pool becomes president
    - The pool is governed by an OpenZeppelin Governor contract. The wrapper token can vote on proposals to e.g. nuke another country
    - The governor is behind a timelock
    - Withdraw your country tokens at any time in exchange for the wrapper token
    - Depositing and withdrawing are subject to the game's 2.5% transfer tax (no fees go to the pool)

## Usage

### Build

```shell
$ forge build
```

### Test

Since country tokens' contracts are not verified, we don't have their source code. Testing is done by forking mainnet state.

```shell
$ forge test --fork-url https://your.base.mainnet.rpc
```
