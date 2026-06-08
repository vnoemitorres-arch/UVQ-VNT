// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SistemaCredencialesUNQ is ERC721URIStorage, AccessControl {
    uint256 private _nextTokenId;

    // Roles profesionales
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct Credential {
        string degreeName;
        bytes32 studentNameHash;
        uint256 issueDate;
        bytes32 documentHash;
        bool active;
    }

    mapping(uint256 => Credential) public credentials;

    // --- Eventos ---
    event CredentialIssued(address indexed student, uint256 indexed tokenId, string degreeName, bytes32 studentNameHash);
    event CredentialRevoked(uint256 indexed tokenId, address indexed by, string reason);
    event IssuerGranted(address indexed account, address indexed by);
    event IssuerRevoked(address indexed account, address indexed by);

    constructor(address rector) ERC721("Diplomatura UNQ", "DUNQ") {
        _grantRole(DEFAULT_ADMIN_ROLE, rector);
        _grantRole(ISSUER_ROLE, rector);
    }

    // --- Funciones Obligatorias: Gestión de Emisores ---

    function grantIssuer(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ISSUER_ROLE, account);
        emit IssuerGranted(account, msg.sender);
    }

    function revokeIssuer(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ISSUER_ROLE, account);
        emit IssuerRevoked(account, msg.sender);
    }

    // --- Funciones Obligatorias: Ciclo de Vida de la Credencial ---

    function issueCredential(
        address student,
        string memory degreeName,
        bytes32 studentNameHash,
        bytes32 documentHash,
        string memory metadataURI
    ) public onlyRole(ISSUER_ROLE) returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        credentials[tokenId] = Credential({
            degreeName: degreeName,
            studentNameHash: studentNameHash,
            issueDate: block.timestamp,
            documentHash: documentHash,
            active: true
        });

        _safeMint(student, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit CredentialIssued(student, tokenId, degreeName, studentNameHash);
        return tokenId;
    }

    function revoke(uint256 tokenId, string memory reason) public onlyRole(ISSUER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Credencial inexistente");
        credentials[tokenId].active = false;
        emit CredentialRevoked(tokenId, msg.sender, reason);
    }

    /**
     * @dev Función de verificación pública para terceros.
     * Devuelve los datos de la credencial y si es válida actualmente [2, 4].
     */
    function verify(uint256 tokenId) public view returns (Credential memory, bool isValid) {
        Credential memory cred = credentials[tokenId];
        bool exists = _ownerOf(tokenId) != address(0);
        return (cred, exists && cred.active);
    }

    // --- Lógica Soulbound (Intransferible) ---

    function _update(address to, uint256 tokenId, address auth)
        internal override returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Las credenciales son intransferibles");
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