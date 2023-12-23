// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title FobNFT
/// @author Ori Wagmi (ori-wagmi)
/// @notice Fob NFT with access control
contract FobNFT is ERC721, AccessControl {
    using Strings for uint256;

    // @var Special roles for mint, burn access.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // @var Map a token to ID to an expiration number.
    // @todo tokenID => block.timestamp?
    mapping(uint256 => uint256) public idToExpiration;

    // Standard events
    event Mint(address indexed owner, uint256 indexed fobNumber);
    event Burn(uint256 indexed fobNumber);
    
    /// @dev Grants admin role to passed address upon initialization.
    /// @param admin (address)
    constructor(address admin) ERC721("Fob", "FOB") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);    
    }

    /// @notice Given a token ID, returns the expiry
    /// @dev    Expiry as string, not protocol prefix as required for URI.
    /// @param tokenId (uint256)
    /// @return  (string)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return idToExpiration[tokenId].toString();
    }

    /// @notice Mint a new token ID to an address.
    /// @dev    Must be non-existant ID. Minter role only.
    /// @param to (adddress)
    /// @param fobNumber (uint256)
    function issue(address to, uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        require(!_exists(fobNumber), "already exists");
        _issue(to, fobNumber);
    }

    /// @notice Burn and re-mint a given token ID.
    /// @dev Must be an existing ID. Minter role only.
    /// @param to (address)
    /// @param fobNumber (uint256)
    function reissue(address to, uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        burn(fobNumber);
        _issue(to, fobNumber);
    }

    /// @notice Extend the expiry time for a given token ID.
    /// @dev Must be an existing ID, adds 30 days to expiry. Minter role only.
    /// @param fobNumber (uint256)
    function extend(uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        idToExpiration[fobNumber] = idToExpiration[fobNumber] + 30 days;
    }

    /// @notice Destroy a given token ID.
    /// @dev Must be an existing ID, delete it, call _burn, emit burn event. Burner role only.
    /// @param fobNumber (uint256)
    function burn(uint256 fobNumber) public onlyRole(BURNER_ROLE) {
        _requireMinted(fobNumber);
        delete idToExpiration[fobNumber];
        _burn(fobNumber);
        emit Burn(fobNumber);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Issue a new token with an expiration.
    /// @dev Internal mint function, add 30 days to current timestamp, emit mint event.
    /// @param to (address)
    /// @param fobNumber (uint256)
    function _issue(address to, uint256 fobNumber) internal {
        idToExpiration[fobNumber] = block.timestamp + 30 days;
        _safeMint(to, fobNumber);
        emit Mint(to, fobNumber);
    }
}
