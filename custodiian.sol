// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustodialWallet {
    address public owner;

    // Solde des utilisateurs
    mapping(address => uint256) private balances;

    // Comptes gelés
    mapping(address => bool) public frozenAccounts;

    // Comptes autorisés à geler/dégeler (admins)
    mapping(address => bool) public authorizedAccounts;

    // Événements
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event AccountFrozen(address indexed user);
    event AccountUnfrozen(address indexed user);
    event Authorized(address indexed account);
    event Revoked(address indexed account);

    constructor() {
        owner = msg.sender;
        authorizedAccounts[owner] = true;
    }

    // Modificateurs
    modifier onlyOwner() {
        require(msg.sender == owner, "Seul le owner peut faire cela");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAccounts[msg.sender], "Non autorise");
        _;
    }

    modifier notFrozen(address user) {
        require(!frozenAccounts[user], "Compte frozen");
        _;
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
    function freezeAccount(address user) external onlyAuthorized {
        frozenAccounts[user] = true;
        emit AccountFrozen(user);
    }

    // Dégeler un compte
    function unfreezeAccount(address user) external onlyAuthorized {
        frozenAccounts[user] = false;
        emit AccountUnfrozen(user);
    }

    // Dépôt de fonds
    function deposit() external payable notFrozen(msg.sender) {
        _deposit(msg.sender, msg.value);
    }

    // Fonction interne pour traitement du dépôt
    function _deposit(address user, uint256 amount) internal {
        require(amount > 0, "Montant nul");
        balances[user] += amount;
        emit Deposit(user, amount);
    }

    // Retrait de fonds
    function withdraw(uint256 amount) external notFrozen(msg.sender) {
        require(balances[msg.sender] >= amount, "Solde insuffisant");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // Consulter le solde d’un utilisateur
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // Retrait d'urgence par le propriétaire
    function emergencyWithdrawAll() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Permet de recevoir des fonds directement
    receive() external payable {
        _deposit(msg.sender, msg.value);
    }
}
