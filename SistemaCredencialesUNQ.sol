// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SistemaCredencialesUNQ is ERC721URIStorage, AccessControl {
    uint256 private _nextTokenId;

    // Roles
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // 3. Struct Credential extendido
    struct Credential {
        string degreeName;       // Ej: "Licenciatura en Sistemas de Información"
        bytes32 studentNameHash; // keccak256(nombre completo + DNI)
        uint256 issueDate;       // timestamp de emisión
        bytes32 documentHash;    // keccak256 del PDF original del título
        bool active;             // Control de revocación
    }

    // Mapeo de ID de Token a la información de la credencial
    mapping(uint256 => Credential) public credentials;

    constructor(address rector) ERC721("Diplomatura UNQ", "DUNQ") {
        _grantRole(DEFAULT_ADMIN_ROLE, rector);
        _grantRole(ISSUER_ROLE, rector);
    }

    /**
     * @dev Emisión de credencial con el struct extendido.
     */
    function emitirCredencial(
        address graduado, 
        string memory uri,
        string memory degreeName,
        bytes32 studentNameHash,
        bytes32 documentHash
    ) public onlyRole(ISSUER_ROLE) {
        uint256 tokenId = _nextTokenId++;
        
        // Almacenamiento de la metadata en el storage del contrato
        credentials[tokenId] = Credential({
            degreeName: degreeName,
            studentNameHash: studentNameHash,
            issueDate: block.timestamp, // Se captura el tiempo real de la blockchain
            documentHash: documentHash,
            active: true
        });

        _safeMint(graduado, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Permite a un emisor revocar una credencial si fuera necesario.
     */
    function revocarCredencial(uint256 tokenId) public onlyRole(ISSUER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "La credencial no existe");
        credentials[tokenId].active = false;
    }

    // --- Lógica Soulbound e interfaces (se mantienen de la versión anterior) ---

    function _update(address to, uint256 tokenId, address auth)
        internal override returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: las credenciales academicas no son transferibles");
        }
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}