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
     * @dev Emisión de credenciales restringida a cuentas con ISSUER_ROLE.
     */
    function emitirCredencial(address graduado, string memory uri) 
        public 
        onlyRole(ISSUER_ROLE) 
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(graduado, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev 2. Lógica Soulbound (no transferible)
     * Se sobrescribe _update para revertir cualquier intento de transferencia 
     * entre direcciones que no sean la dirección cero (mint/burn).
     */
    function _update(address to, uint256 tokenId, address auth)
        internal 
        override 
        returns (address)
    {
        address from = _ownerOf(tokenId);
        // Si no es un minteo (from == 0) ni un quemado (to == 0), es una transferencia
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: las credenciales academicas no son transferibles");
        }
        return super._update(to, tokenId, auth);
    }

    // Funciones de soporte requeridas por Solidity para herencia múltiple
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}