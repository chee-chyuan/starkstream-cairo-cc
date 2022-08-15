%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from openzeppelin.token.erc20.IERC20 import IERC20

from src.m_token import get_owner, get_underlying_token_addr, wrap
from tests.utils.Im_token import Im_token

const OWNER_ADDRESS = 123456
const TEST_USER_ADDRESS = 123123

@external
func __setup__():
    tempvar erc20_address
    %{
        context.erc20_address = deploy_contract(
        "./src/ERC20MintableBurnable.cairo",
        [   1111, # name
            1111, # symbol 
            18,   # decimal 
            1000000,0, # initial supply
            # ids.OWNER_ADDRESS, # recipient
            ids.TEST_USER_ADDRESS, # recipient
            ids.OWNER_ADDRESS, # owner
        ]
        ).contract_address
        ids.erc20_address = context.erc20_address

        context.contract_address = deploy_contract(
           "./src/m_token.cairo",
           [
                777,             # name
                777,             # symbol
                # 18,               # decimals
                ids.OWNER_ADDRESS, # owner
                ids.erc20_address # underlying token_addr
            ]
           ).contract_address
    %}
    return ()
end

@external
func test_wrap_token{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    tempvar erc20_address
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        ids.erc20_address = context.erc20_address
        stop_prank_callable = start_prank(ids.TEST_USER_ADDRESS, target_contract_address=ids.contract_address)
        stop_prank_callable2 = start_prank(ids.TEST_USER_ADDRESS, target_contract_address=ids.erc20_address)
    %}
    local contract_address = contract_address
    local erc20_address = erc20_address

    IERC20.approve(contract_address=erc20_address, spender=contract_address, amount=Uint256(100,0))
    ## this approval does not make sense ?! 
    IERC20.approve(contract_address=erc20_address, spender=TEST_USER_ADDRESS, amount=Uint256(100,0))

    let (total_supply_before : Uint256) = Im_token.total_supply(contract_address=contract_address)
    let (m_token_bal_in_wallet_before : Uint256) = Im_token.balance_of(contract_address=contract_address, account=TEST_USER_ADDRESS)
    local total_supply_before : Uint256 = total_supply_before
    local m_token_bal_in_wallet_before : Uint256 = m_token_bal_in_wallet_before
    %{print(f"[Before wrap]m_token total_supply_before.low: {ids.total_supply_before.low}")%}
    # %{print(f"[Before wrap]user's m_token_bal_in_wallet_before.low: {ids.m_token_bal_in_wallet_before.low}")%}
    ##################################################################
    #### WRAP section
    ##################################################################
    Im_token.wrap(contract_address=contract_address,amount=Uint256(10,0)) 

    ##################################################################
    #### check remaining underlying balance in user's wallet
    ##################################################################
    let (erc20_token_bal : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=TEST_USER_ADDRESS)
    local erc20_token_bal : Uint256 = erc20_token_bal
    %{print(f"[After wrap]user's erc20_token_bal.low: {ids.erc20_token_bal.low}")%}
    # %{print(f"[After wrap]user's erc20_token_bal.high: {ids.erc20_token_bal.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(999990,0), erc20_token_bal)
    assert is_balance_eq = 1
    ##################################################################
    #### check remaining erc20 token balance in m_token contract
    ##################################################################
    let (erc20_token_bal_in_m_token_contract : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=contract_address)
    local erc20_token_bal_in_m_token_contract : Uint256 = erc20_token_bal_in_m_token_contract
    %{print(f"[After wrap]m_token's erc20_token_bal.low: {ids.erc20_token_bal_in_m_token_contract.low}")%}
    # %{print(f"[After wrap]m_token's erc20_token_bal.high: {ids.erc20_token_bal_in_m_token_contract.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(10,0), erc20_token_bal_in_m_token_contract)
    assert is_balance_eq = 1
    ##################################################################
    #### check remaining m_token token balance in user's wallet
    ##################################################################
    let (total_supply_after : Uint256) = Im_token.total_supply(contract_address=contract_address)
    let (m_token_bal_in_wallet : Uint256) = Im_token.balance_of(contract_address=contract_address, account=TEST_USER_ADDRESS)
    local total_supply_after : Uint256 = total_supply_after
    local m_token_bal_in_wallet : Uint256 = m_token_bal_in_wallet
    %{print(f"[After wrap]m_token total_supply_after.low: {ids.total_supply_after.low}")%}
    %{print(f"[After wrap]user's m_token_bal_in_wallet.low: {ids.m_token_bal_in_wallet.low}")%}
    # %{print(f"[After wrap]user's m_token_bal_in_wallet.high: {ids.m_token_bal_in_wallet.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(10,0), m_token_bal_in_wallet)
    assert is_balance_eq = 1
    ##################################################################
    #### UNWRAP section
    ##################################################################
    Im_token.unwrap(contract_address=contract_address,amount=Uint256(7,0)) 
    ##################################################################
    #### check remaining m_token token balance in user's wallet
    ##################################################################
    let (total_supply_after : Uint256) = Im_token.total_supply(contract_address=contract_address)
    let (m_token_bal_in_wallet : Uint256) = Im_token.balance_of(contract_address=contract_address, account=TEST_USER_ADDRESS)
    local total_supply_after : Uint256 = total_supply_after
    local m_token_bal_in_wallet : Uint256 = m_token_bal_in_wallet
    %{print(f"[After UNwrap]m_token total_supply_after.low: {ids.total_supply_after.low}")%}
    %{print(f"[After UNwrap]user's m_token_bal_in_wallet.low: {ids.m_token_bal_in_wallet.low}")%}
    # %{print(f"[After wrap]user's m_token_bal_in_wallet.high: {ids.m_token_bal_in_wallet.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(3,0), m_token_bal_in_wallet)
    assert is_balance_eq = 1
    ##################################################################
    #### check remaining erc20 token balance in m_token contract
    ##################################################################
    let (erc20_token_bal_in_m_token_contract_2 : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=contract_address)
    local erc20_token_bal_in_m_token_contract_2 : Uint256 = erc20_token_bal_in_m_token_contract_2
    %{print(f"[After UNwrap]m_token's erc20_token_bal.low: {ids.erc20_token_bal_in_m_token_contract_2.low}")%}
    # %{print(f"[After UNwrap]m_token's erc20_token_bal.high: {ids.erc20_token_bal_in_m_token_contract_2.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(3,0), erc20_token_bal_in_m_token_contract_2)
    assert is_balance_eq = 1
    ##################################################################
    #### check remaining underlying balance in user's wallet
    ##################################################################
    let (unwrapped_erc20_token_bal : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=TEST_USER_ADDRESS)
    local unwrapped_erc20_token_bal : Uint256 = unwrapped_erc20_token_bal
    %{print(f"[After Unwrap]user's unwrapped_erc20_token_bal.low: {ids.unwrapped_erc20_token_bal.low}")%}
    # %{print(f"[After Unwrap]user's unwrapped_erc20_token_bal.high: {ids.unwrapped_erc20_token_bal.high}")%}
    let (is_balance_eq) = uint256_eq(Uint256(999997,0), unwrapped_erc20_token_bal)
    assert is_balance_eq = 1
    %{
        stop_prank_callable()
        stop_prank_callable2()
    %}
    return()
end

