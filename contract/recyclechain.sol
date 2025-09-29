// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RecycleChain
 * @dev A smart contract for incentivizing recycling through blockchain technology
 * @author RecycleChain Team
 */
contract Project {
    
    // State variables
    address public owner;
    uint256 public totalRecycledWeight;
    uint256 public totalTokensIssued;
    uint256 public constant TOKENS_PER_KG = 10; // 10 tokens per kg recycled
    
    // Structs
    struct RecycleRecord {
        address recycler;
        uint256 weight;
        string materialType;
        uint256 timestamp;
        bool verified;
    }
    
    struct User {
        uint256 tokenBalance;
        uint256 totalRecycled;
        uint256 recordCount;
        bool isRegistered;
    }
    
    // Mappings
    mapping(address => User) public users;
    mapping(uint256 => RecycleRecord) public recycleRecords;
    mapping(address => bool) public verifiers;
    
    // Events
    event UserRegistered(address indexed user);
    event RecyclingRecorded(uint256 indexed recordId, address indexed recycler, uint256 weight, string materialType);
    event RecyclingVerified(uint256 indexed recordId, address indexed verifier);
    event TokensAwarded(address indexed recycler, uint256 amount);
    event VerifierAdded(address indexed verifier);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Only verified verifiers can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    uint256 public recordCounter;
    
    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true; // Owner is also a verifier
    }
    
    /**
     * @dev Core Function 1: Register a new user in the system
     */
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            tokenBalance: 0,
            totalRecycled: 0,
            recordCount: 0,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender);
    }
    
    /**
     * @dev Core Function 2: Record recycling activity
     * @param _weight Weight of recycled material in grams
     * @param _materialType Type of material recycled (e.g., "plastic", "paper", "glass")
     */
    function recordRecycling(uint256 _weight, string memory _materialType) external onlyRegistered {
        require(_weight > 0, "Weight must be greater than zero");
        require(bytes(_materialType).length > 0, "Material type cannot be empty");
        
        recordCounter++;
        
        recycleRecords[recordCounter] = RecycleRecord({
            recycler: msg.sender,
            weight: _weight,
            materialType: _materialType,
            timestamp: block.timestamp,
            verified: false
        });
        
        users[msg.sender].recordCount++;
        
        emit RecyclingRecorded(recordCounter, msg.sender, _weight, _materialType);
    }
    
    /**
     * @dev Core Function 3: Verify recycling record and award tokens
     * @param _recordId ID of the recycling record to verify
     */
    function verifyRecycling(uint256 _recordId) external onlyVerifier {
        require(_recordId > 0 && _recordId <= recordCounter, "Invalid record ID");
        require(!recycleRecords[_recordId].verified, "Record already verified");
        
        RecycleRecord storage record = recycleRecords[_recordId];
        record.verified = true;
        
        // Convert grams to kg and calculate tokens
        uint256 weightInKg = record.weight / 1000;
        uint256 tokensToAward = weightInKg * TOKENS_PER_KG;
        
        // Update user stats
        User storage user = users[record.recycler];
        user.tokenBalance += tokensToAward;
        user.totalRecycled += record.weight;
        
        // Update global stats
        totalRecycledWeight += record.weight;
        totalTokensIssued += tokensToAward;
        
        emit RecyclingVerified(_recordId, msg.sender);
        emit TokensAwarded(record.recycler, tokensToAward);
    }
    
    // Additional utility functions
    function addVerifier(address _verifier) external onlyOwner {
        verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }
    
    function getUserInfo(address _user) external view returns (User memory) {
        return users[_user];
    }
    
    function getRecycleRecord(uint256 _recordId) external view returns (RecycleRecord memory) {
        return recycleRecords[_recordId];
    }
    
    function getContractStats() external view returns (uint256, uint256, uint256) {
        return (totalRecycledWeight, totalTokensIssued, recordCounter);
    }
}
