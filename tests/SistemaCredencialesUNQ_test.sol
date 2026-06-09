// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol";
import "../SistemaCredencialesUNQ.sol"; 
// IMPORT SOLICITADO INTEGRADO PARA REMIX
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SistemaCredencialesUNQTest {
    SistemaCredencialesUNQ public sistema;
    address rector = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address decano = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address alumno = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address intruso = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    // Datos de prueba
    bytes32 public studentHash = keccak256(abi.encodePacked("Juan Perez", "12345678"));
    bytes32 public docHash = keccak256(abi.encodePacked("PDF_TITULO_ORIGINAL"));
    string public uri = "ipfs://bafybeic...metadata.json";

    function beforeEach() public {
        sistema = new SistemaCredencialesUNQ(rector);
    }

    // --- 1. CAMINO FELIZ (Happy Path) ---

    function test_AdminAgregaIssuerYVerificaRol() public {
        sistema.grantIssuer(decano);
        Assert.equal(sistema.hasRole(sistema.ISSUER_ROLE(), decano), true, "El decano deberia tener el rol de Issuer");
    }

    function test_IssuerEmiteYGuardaDatosCorrectamente() public {
        sistema.grantIssuer(address(this)); 

        uint256 tokenId = sistema.issueCredential(alumno, "Licenciatura en Sistemas", studentHash, docHash, uri);

        (SistemaCredencialesUNQ.Credential memory cred, bool isValid) = sistema.verify(tokenId);

        Assert.equal(cred.degreeName, "Licenciatura en Sistemas", "El nombre de la carrera no coincide");
        Assert.equal(cred.studentNameHash, studentHash, "El hash del estudiante no coincide");
        Assert.equal(cred.documentHash, docHash, "El hash del documento no coincide");
        Assert.equal(isValid, true, "La credencial deberia ser valida");
        Assert.equal(sistema.ownerOf(tokenId), alumno, "El dueno deberia ser el alumno");
    }

    function test_IssuerRevocaYVerificacionFalla() public {
        sistema.grantIssuer(address(this));
        uint256 tokenId = sistema.issueCredential(alumno, "Ingenieria", studentHash, docHash, uri);

        sistema.revoke(tokenId, "Error en carga de datos");

        (, bool isValid) = sistema.verify(tokenId);
        Assert.equal(isValid, false, "La credencial no deberia ser valida tras revocacion");
    }

    // --- 2. CASOS DE ERROR (Revert Testing en Remix) ---

    /// #sender: 0x78731D3Ca6b7E34aC0F824c42a7cc18A495cabaB
    /// #expectRevert: true
    function test_RevertirEmisionSinIssuerRole() public {
        sistema.issueCredential(alumno, "Fraude", studentHash, docHash, uri);
    }

    /// #expectRevert: true
    function test_RevertirTransferenciaSoulbound() public {
        sistema.grantIssuer(address(this));
        uint256 id = sistema.issueCredential(alumno, "Titulo SBT", studentHash, docHash, uri);
        sistema.transferFrom(alumno, intruso, id);
    }

    /// #expectRevert: true
    function test_RevertirRevocacionInexistente() public {
        sistema.grantIssuer(address(this));
        sistema.revoke(999, "No existe");
    }

    // --- 3. ADAPTACIÓN DE FUZZ TESTING ---

    function testRemix_issueCredentialValoresFijos() public {
          address[3] memory estudiantesDePrueba = [
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
        ];
        
        sistema.grantIssuer(address(this));

        for(uint i = 0; i < estudiantesDePrueba.length; i++) {
            address estudiante = estudiantesDePrueba[i];
            uint256 id = sistema.issueCredential(estudiante, "Carrera Iterada", studentHash, docHash, "ipfs://test");
            Assert.equal(sistema.ownerOf(id), estudiante, "El dueno asignado en el bucle es incorrecto");
        }
    }
}
