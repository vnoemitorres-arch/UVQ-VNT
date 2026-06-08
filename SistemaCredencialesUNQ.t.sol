// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import "../src/SistemaCredencialesUNQ.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract SistemaCredencialesUNQTest is Test {
    SistemaCredencialesUNQ public sistema;

    // Cuentas para simular actores institucionales
    address public rector = address(0x1);
    address public decano = address(0x2);
    address public alumno = address(0x3);
    address public intruso = address(0x4);

    // Datos de prueba con hashing para privacidad (Commitment Scheme) [5-7]
    bytes32 public studentHash = keccak256(abi.encodePacked("Juan Perez", "12345678"));
    bytes32 public docHash = keccak256(abi.encodePacked("PDF_TITULO_ORIGINAL"));
    string public uri = "ipfs://bafybeic...metadata.json";

    function setUp() public {
        // Despliegue inicial: el Rector es el DEFAULT_ADMIN_ROLE [4]
        sistema = new SistemaCredencialesUNQ(rector);
    }

    // --- 1. CAMINO FELIZ (Happy Path) ---

    function test_AdminAgregaIssuerYVerificaRol() public {
        vm.prank(rector); // Cheatcode para simular la cuenta del rector [8]
        sistema.grantIssuer(decano);
        
        assertTrue(sistema.hasRole(sistema.ISSUER_ROLE(), decano));
    }

    function test_IssuerEmiteYGuardaDatosCorrectamente() public {
        vm.prank(rector);
        sistema.grantIssuer(decano);

        vm.prank(decano);
        uint256 tokenId = sistema.issueCredential(alumno, "Licenciatura en Sistemas", studentHash, docHash, uri);

        (SistemaCredencialesUNQ.Credential memory cred, bool isValid) = sistema.verify(tokenId);

        assertEq(cred.degreeName, "Licenciatura en Sistemas");
        assertEq(cred.studentNameHash, studentHash);
        assertEq(cred.documentHash, docHash);
        assertTrue(isValid);
        assertEq(sistema.ownerOf(tokenId), alumno);
    }

    function test_IssuerRevocaYVerificacionFalla() public {
        vm.prank(rector);
        sistema.grantIssuer(decano);
        vm.prank(decano);
        uint256 tokenId = sistema.issueCredential(alumno, "Ingenieria", studentHash, docHash, uri);

        vm.prank(decano);
        sistema.revoke(tokenId, "Error en carga de datos");

        (, bool isValid) = sistema.verify(tokenId);
        assertFalse(isValid);
    }

    // --- 2. CASOS DE ERROR ---

    function test_RevertirEmisionSinIssuerRole() public {
        vm.prank(intruso);
        // Espera el error de AccessControl de OpenZeppelin v5 [4]
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, 
                intruso, 
                sistema.ISSUER_ROLE()
            )
        );
        sistema.issueCredential(alumno, "Fraude", studentHash, docHash, uri);
    }

    function test_RevertirTransferenciaSoulbound() public {
        vm.prank(rector);
        sistema.grantIssuer(decano);
        vm.prank(decano);
        uint256 id = sistema.issueCredential(alumno, "Titulo SBT", studentHash, docHash, uri);

        vm.prank(alumno);
        vm.expectRevert("Soulbound: Las credenciales son intransferibles");
        sistema.transferFrom(alumno, intruso, id);
    }

    function test_RevertirRevocacionInexistente() public {
        vm.prank(rector);
        sistema.grantIssuer(decano);
        
        vm.prank(decano);
        vm.expectRevert("Credencial inexistente");
        sistema.revoke(999, "No existe");
    }

    function test_RevertirGestionIssuerSinAdminRole() public {
        vm.prank(decano);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, 
                decano, 
                0x00 // DEFAULT_ADMIN_ROLE
            )
        );
        sistema.grantIssuer(intruso);
    }

    // --- 3. FUZZ TESTING ---

    /**
     * @dev Fuzz test para verificar que el dueño siempre sea el estudiante asignado.
     * Foundry ejecutará esto con cientos de combinaciones aleatorias [8, 9].
     */
    function testFuzz_issueCredential(address student, string memory metadataURI) public {
        // Regla: el estudiante no puede ser la dirección cero
        vm.assume(student != address(0)); 
        
        vm.prank(rector);
        sistema.grantIssuer(decano);

        vm.prank(decano);
        uint256 id = sistema.issueCredential(student, "Carrera Fuzz", studentHash, docHash, metadataURI);

        assertEq(sistema.ownerOf(id), student);
    }
}