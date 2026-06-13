// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../SistemaCredencialesUNQ.sol"; // Verificá que la ruta sea correcta

contract SistemaCredencialesUNQTest {
    SistemaCredencialesUNQ sistema;
    address decano;
    address alumno;

    // Datos para el Commitment Scheme (Privacidad)
    bytes32 studentHash = keccak256(abi.encodePacked("Juan Perez", "12345678"));
    bytes32 docHash = keccak256(abi.encodePacked("PDF_TITULO"));

    function beforeAll() public {
        decano = TestsAccounts.getAccount(1);
        alumno = TestsAccounts.getAccount(2);
        
        // ¡CLAVE! Le damos los roles al contrato de TEST para que pueda operar
        sistema = new SistemaCredencialesUNQ(address(this));
    }

    // --- CAMINO FELIZ (Happy Path) ---

    function testAdminAgregaIssuer() public {
        sistema.grantIssuer(decano);
        Assert.equal(sistema.hasRole(sistema.ISSUER_ROLE(), decano), true, "El decano deberia tener el rol");
    }

    function testIssuerEmiteCredencial() public {
        // El test tiene ISSUER_ROLE por el constructor, emite directamente
        uint256 id = sistema.issueCredential(alumno, "Licenciatura", studentHash, docHash, "ipfs://uri");
        
        (SistemaCredencialesUNQ.Credential memory cred, bool isValid) = sistema.verify(id);
        Assert.equal(isValid, true, "Deberia ser valida");
        Assert.equal(cred.degreeName, "Licenciatura", "Nombre carrera incorrecto");
    }

    function testIssuerRevocaCredencial() public {
        // Revocamos el ID 0 (emitido en el test anterior)
        sistema.revoke(0, "Error administrativo");
        (, bool isValid) = sistema.verify(0);
        Assert.equal(isValid, false, "Debe estar inactiva tras revocacion");
    }

    // --- CASOS DE ERROR ---

    function testFallarEmisionSinRol() public {
        // El contrato de test se quita el rol a sí mismo para probar el error
        sistema.revokeRole(sistema.ISSUER_ROLE(), address(this));
        
        try sistema.issueCredential(alumno, "Falla", studentHash, docHash, "uri") {
            Assert.ok(false, "Deberia haber fallado por falta de rol");
        } catch {
            Assert.ok(true, "Revirtio correctamente");
        }
        
        // Restauramos el rol para los siguientes tests
        sistema.grantRole(sistema.ISSUER_ROLE(), address(this));
    }

    function testFallarTransferenciaSoulbound() public {
        // Emitimos una nueva credencial (ID 1)
        uint256 id = sistema.issueCredential(alumno, "Soulbound Test", studentHash, docHash, "uri");
        
        try sistema.transferFrom(alumno, decano, id) {
            Assert.ok(false, "Deberia haber fallado por ser Soulbound");
        } catch Error(string memory reason) {
            // Verificamos el mensaje de error definido en el contrato
            Assert.equal(reason, "Soulbound: Las credenciales son intransferibles", "Mensaje de error incorrecto");
        }
    }

    // --- FUZZ TESTING (Simulado en Remix) ---

    function testFuzz_issueCredential() public {
        // En Remix es un Unit Test, en Foundry seria con cientos de inputs [5, 6]
        address randomStudent = address(0x123);
        uint256 id = sistema.issueCredential(randomStudent, "Fuzz", studentHash, docHash, "uri");
        Assert.equal(sistema.ownerOf(id), randomStudent, "El owner debe ser el estudiante");
    }
}