// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC1363} from "@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract UCOIN is 
    ERC20, 
    ERC20Burnable, 
    ERC20Pausable, 
    Ownable, 
    ERC1363, 
    ERC20Permit, 
    ERC20Votes, 
    ERC20FlashMint 
{
    // Comptes gelés
    mapping(address => bool) public frozenAccounts;

    // Comptes autorisés à geler/dégeler
    mapping(address => bool) public authorizedAccounts;

    // Events
    event AccountFrozen(address indexed user);
    event AccountUnfrozen(address indexed user);
    event Authorized(address indexed account);
    event Revoked(address indexed account);

    constructor(address recipient, address initialOwner)
        ERC20("UCOIN", "UCN")
        Ownable(initialOwner)
        ERC20Permit("UCOIN")
    {
        _mint(recipient, 1000000 * 10 ** decimals());
        authorizedAccounts[initialOwner] = true; // Le créateur peut geler/dégeler
    }

    // Autoriser un compte à geler/dégeler
    function authorizeAccount(address account) external onlyOwner {
        authorizedAccounts[account] = true;
        emit Authorized(account);
    }

    // Révoquer les droits d’un compte
    function revokeAuthorization(address account) external onlyOwner {
        authorizedAccounts[account] = false;
        emit Revoked(account);
    }

    // Geler un compte
    function freezeAccount(address user) external {
        require(authorizedAccounts[msg.sender], "No authorization");
        frozenAccounts[user] = true;
        emit AccountFrozen(user);
    }

    // Dégeler un compte
    function unfreezeAccount(address user) external {
        require(authorizedAccounts[msg.sender], "No authorization");
        frozenAccounts[user] = false;
        emit AccountUnfrozen(user);
    }

    // Blocage des transferts si compte gelé
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable, ERC20Votes)
    {
        require(!frozenAccounts[from], "Sender frozen");
        require(!frozenAccounts[to], "Reciever frozen");
        super._update(from, to, value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
