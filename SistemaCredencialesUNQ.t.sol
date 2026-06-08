// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

// Importaciones directas compatibles con Remix
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SistemaCredencialesUNQ is ERC721URIStorage, AccessControl {
    uint256 private _nextTokenId;

    // Roles Institucionales
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // 3. Struct Credential extendido para Privacidad
    struct Credential {
        string degreeName;       // Ej: "Licenciatura en Sistemas"
        bytes32 studentNameHash; // keccak256(nombre + DNI)
        uint256 issueDate;       // Timestamp inmutable
        bytes32 documentHash;    // keccak256 del PDF original
        bool active;             // Estado de validez
    }

    mapping(uint256 => Credential) public credentials;

    // Eventos para auditoría y frontend
    event CredentialIssued(address indexed student, uint256 indexed tokenId, string degreeName, bytes32 studentNameHash);
    event CredentialRevoked(uint256 indexed tokenId, address indexed by, string reason);
    event IssuerGranted(address indexed account, address indexed by);
    event IssuerRevoked(address indexed account, address indexed by);

    constructor(address rector) ERC721("Diplomatura UNQ", "DUNQ") {
        _grantRole(DEFAULT_ADMIN_ROLE, rector); // Rector gestiona emisores
        _grantRole(ISSUER_ROLE, rector);        // Rector también puede emitir inicialmente
    }

    // --- Gestión de Emisores (Sólo Admin) ---
    function grantIssuer(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ISSUER_ROLE, account);
        emit IssuerGranted(account, msg.sender);
    }

    function revokeIssuer(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ISSUER_ROLE, account);
        emit IssuerRevoked(account, msg.sender);
    }

    // --- Ciclo de Vida de la Credencial (Sólo Issuers) ---
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
        require(_ownerOf(tokenId) != address(0), "La credencial no existe");
        credentials[tokenId].active = false;
        emit CredentialRevoked(tokenId, msg.sender, reason);
    }

    // --- Verificación Pública ---
    function verify(uint256 tokenId) public view returns (Credential memory, bool isValid) {
        Credential memory cred = credentials[tokenId];
        bool exists = _ownerOf(tokenId) != address(0);
        return (cred, exists && cred.active);
    }

    // --- 2. Lógica Soulbound (NFT No Transferible) ---
    function _update(address to, uint256 tokenId, address auth)
        internal override returns (address)
    {
        address from = _ownerOf(tokenId);
        // Bloquea transferencias entre cuentas (solo permite minting y burning)
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Las credenciales son intransferibles");
        }
        return super._update(to, tokenId, auth);
    }

    // Soporte para interfaces de OpenZeppelin
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}