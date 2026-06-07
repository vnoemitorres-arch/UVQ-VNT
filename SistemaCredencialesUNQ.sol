// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

// Importaciones directas para Remix usando el estándar de OpenZeppelin v5.x
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SistemaCredencialesUNQ is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    // Evento para rastrear la emisión en el frontend o exploradores
    event CredencialEmitida(address indexed graduado, uint256 indexed tokenId, string uri);

    constructor() ERC721("Diplomatura UNQ", "DUNQ") Ownable(msg.sender) {}

    /**
     * @dev Emite una nueva credencial académica. 
     * Solo puede ser llamada por la dirección de la Universidad (Owner).
     * @param graduado Dirección de la wallet del alumno.
     * @param uri Enlace a IPFS con el hash del título y metadata (Privacidad off-chain).
     */
    function emitirCredencial(address graduado, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(graduado, tokenId);
        _setTokenURI(tokenId, uri);

        emit CredencialEmitida(graduado, tokenId, uri);
    }
}