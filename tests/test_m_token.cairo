%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from openzeppelin.token.erc20.IERC20 import IERC20

from src.m_token import get_owner, get_underlying_token_addr, wrap
from tests.utils.Im_token import Im_token

const OWNER_ADDRESS = 123456

@view
func __setup__():
    tempvar erc20_address
    
    %{
        context.erc20_address = deploy_contract(
        "./src/ERC20MintableBurnable.cairo",
        [   1111, # name
            1111, # symbol 
            18,   # decimal 
            1000000,1000000, # initial supply
            ids.OWNER_ADDRESS, # recipient
            ids.OWNER_ADDRESS, # owner
        ]
        ).contract_address
        ids.erc20_address = context.erc20_address

        context.contract_address = deploy_contract(
           "./src/m_token.cairo",
           [
                777,             # name
                777,             # symbol
                # 18,               # owner
                ids.OWNER_ADDRESS, # owner
                ids.erc20_address # underlying token_addr
            ]
           ).contract_address
    %}
    return ()
end

@view
func test_init_constructor_correctly{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    tempvar contract_address
    tempvar erc20_address
    tempvar balance
    %{
        ids.contract_address = context.contract_address
        ids.erc20_address = context.erc20_address
    %}
    # check if underlying_token of m_token is matching
    let (underlying_token) = Im_token.get_underlying_token_addr(contract_address=contract_address)
    %{
        print(f"underlying_token:{ids.erc20_address}")
    %}
    assert underlying_token = erc20_address
    return ()
end

@view
func test_wallet_balance_minted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    tempvar erc20_address
    tempvar balance_low
    %{
        ids.erc20_address = context.erc20_address
    %}
    let (balance : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=OWNER_ADDRESS)
    local balance : Uint256 = balance
    %{
        print(f"owner's balance.low: {ids.balance.low}")
        print(f"owner's balance.low: {ids.balance.high}")
        
    %}
    let (is_balance_eq) = uint256_eq(Uint256(1000000,1000000), balance)
    assert is_balance_eq = 1
    return ()
end


@view
func test_wrap_token{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    tempvar erc20_address
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        ids.erc20_address = context.erc20_address
    %}
    # transfer underlying to m_token contract
    Im_token.wrap(contract_address=contract_address,amount=Uint256(10,0)) 
    # let (balance : Uint256) = IERC20.balanceOf(contract_address=erc20_address, account=contract_address)
    # local balance : Uint256 = balance

    # %{
    #     print(f"owner's balance.low: {ids.balance.low}")
    #     print(f"owner's balance.low: {ids.balance.high}")
        
    # %}
    return()
end