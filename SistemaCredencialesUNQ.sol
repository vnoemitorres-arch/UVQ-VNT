// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SistemaCredencialesUNQ is ERC721URIStorage, AccessControl {
    uint256 private _nextTokenId;

    // Definición de Roles
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    constructor(address rector) ERC721("Diplomatura UNQ", "DUNQ") {
        _grantRole(DEFAULT_ADMIN_ROLE, rector);
        _grantRole(ISSUER_ROLE, rector);
    }

    /**
     * @dev Ahora la variable _nextTokenId existe y se puede incrementar.
     */
    function emitirCredencial(address graduado, string memory uri) 
        public 
        onlyRole(ISSUER_ROLE) 
    {
        uint256 tokenId = _nextTokenId++; // Se incrementa el ID para la próxima emisión
        _safeMint(graduado, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Soporte para AccessControl y ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}