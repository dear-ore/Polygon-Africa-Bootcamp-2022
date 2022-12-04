//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.17;

contract Chemotronix is ERC20 {

    uint256 constant fixedFee = 1 ether; // annual subscription fees for Chemotronix services
    address payable public admin;

    constructor() ERC20("Chemotronix", "CMX") {
        admin = payable(msg.sender);
    }

    enum subStatus {
        expired,
        active
    }

    enum industryTypes {
        energy,
        agriculture,
        landUseChange,
        industrialProcesses,
        waste
    }

    // mechanism to mint different quantity of tokens for different industries
    // this is done because of the different nature of different industries, each will have
    // different lower limit of possible carbon emission
    uint256[5] tokenSupplyPerCompany = [1000000000 * 10**9, 750000000 * 10**9, 500000000 * 10**9, 250000000 * 10**9, 100000000 * 10**9];

    struct company {
        address companyAddress;
        uint registrationTime;
        subStatus sub;
        industryTypes industry;
    }

    mapping(string => company) private IDtoCompany; // IoT ID to its details
    mapping(string => bool) private isIDregistered; // checks if IoT device is already registered
    mapping(address => string) private addressToID; // company's wallet address to IoT ID

    event registration(string indexed uniqueID, uint256 registrationTime, address indexed companyAddress);
    event fundsWithdrawn(uint amount, address indexed admin);
    event balanceChecked(uint amount);

    function decimals() public view virtual override returns(uint8) {
        return 9;
    }

    // this function is automated by Chainlink Keeper to be executed once every 365 days
    function tokenAnnualSupply() external {
        for(uint i = 0; i < tokenSupplyPerCompany.length; i++) {
            tokenSupplyPerCompany[i] = (9*tokenSupplyPerCompany[i])/10; // number of tokens distributed each year is 10% less than previous year
        }
    }

    function register(string memory uniqueID, industryTypes industry) external payable unregistered(uniqueID) {
        require(msg.value == fixedFee, "You do not have the correct registration fee");
        require(!isIDregistered[uniqueID], "The IoT device has already been registered");
        IDtoCompany[uniqueID] = company(
            msg.sender,
            block.timestamp,
            subStatus.active,
            industry
        );
        company memory myCompany = IDtoCompany[uniqueID];
        addressToID[msg.sender] = uniqueID;
        isIDregistered[uniqueID] = true;
        _mint(myCompany.companyAddress, tokenSupplyPerCompany[uint(industry)]); // giving the company alloted tokens
        
        emit registration(uniqueID, myCompany.registrationTime, myCompany.companyAddress);
        emit Transfer(admin, myCompany.companyAddress, tokenSupplyPerCompany[uint(industry)]);
    }

    function checkTimeForRegistrationDeregistration(string memory uniqueID) public view onlySelectedAddresses(uniqueID) returns(uint) {
        // returns time left for deregistration (1 year i.e 31536000 seconds since registration)
        return 31536000 - (block.timestamp - IDtoCompany[uniqueID].registrationTime);
    }

    function deregister(string memory uniqueID) external onlyAdmin registered(uniqueID) {
        require(checkTimeForRegistrationDeregistration(uniqueID) == 0, "Company cannot be deregistered yet");
        IDtoCompany[uniqueID].sub = subStatus.expired;
    }

    function checkRegistrationStatus(string memory uniqueID) external view onlySelectedAddresses(uniqueID) returns(subStatus){
        // returns current registration status
        return IDtoCompany[uniqueID].sub;
    }

    function renewRegistration(string memory uniqueID) external payable unregistered(uniqueID) {
        require(msg.value == fixedFee, "You do not have the correct registration fee");
        company memory myCompany = IDtoCompany[uniqueID];
        myCompany.registrationTime = block.timestamp;
        myCompany.sub = subStatus.active;
        _mint(myCompany.companyAddress, tokenSupplyPerCompany[uint(myCompany.industry)]); // do this when subscription is renewed
        emit registration(uniqueID, myCompany.registrationTime, myCompany.companyAddress);
    }

    // Admin view
    function changeTokenAllocation(industryTypes industry, uint256 newSupply) external onlyAdmin {
        // mechanism to reduce token quantity per industry by admin
        tokenSupplyPerCompany[uint(industry)] = newSupply;
    }

    // called hourly
    function offset(uint256 weight, string memory uniqueID) external {
        // burns CMX tokens of the company in accordance to how much CO2 has been emitted
        _burn(IDtoCompany[uniqueID].companyAddress, weight);
    }

    // Admin view
    function withdrawEarnings(uint256 amount) external onlyAdmin { // allows admin to transfer contract funds to their wallet
        admin.transfer(amount);
        emit fundsWithdrawn(amount, admin);
    }

    function checkContractFundBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getIndustryType(string memory uniqueID) external view returns(industryTypes) {
        return IDtoCompany[uniqueID].industry;
    }

    function getIDtoCompany(string memory uniqueID) external view returns(company memory) {
        return IDtoCompany[uniqueID];
    }

    function getAddresstoID() external view returns(string memory) {
        return addressToID[msg.sender];
    }

    function checkTokenBalance(string memory uniqueID) public returns(uint) {
        uint bal = balanceOf(IDtoCompany[uniqueID].companyAddress);
        emit balanceChecked(bal);
        return bal;
    }

    modifier onlyAdmin() {
        require (msg.sender == admin, "You do not have permission to call this function");
        _;
    }

    modifier unregistered(string memory uniqueID) {
        require(IDtoCompany[uniqueID].sub != subStatus.active, "A company with this"); // checks that company is not already registered
        _;
    }

    modifier registered(string memory uniqueID) {
        require(IDtoCompany[uniqueID].sub == subStatus.active); // checks that company is already registered
        _;
    }

    modifier onlySelectedAddresses(string memory uniqueID) {
        require(msg.sender == IDtoCompany[uniqueID].companyAddress || msg.sender == admin || msg.sender == admin);
        _;
    }
}