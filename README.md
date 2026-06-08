Modelado y Arquitectura (Diagramas Mermaid)
Podés incluir estos diagramas directamente en tu README.md
:
Diagrama de Componentes:
graph TD
    A[Wallet Rector/Decano] -->|Firma Tx| B(Contrato en Base Sepolia)
    C[Frontend DApp] -->|Consulta| B
    C -->|Lee Metadata| D[IPFS Pinata]
    E[Browser Verificador] -->|Ingresa ID| C
Flujo de Emisión:
sequenceDiagram
    Rector->>Contrato: grantIssuer(Decano_Address)
    Decano->>Contrato: issueCredential(Alumno, Datos_Hash, IPFS_URI)
    Contrato->>Blockchain: Emitir Evento CredentialIssued
    Alumno->>MetaMask: Recibe NFT Soulbound
