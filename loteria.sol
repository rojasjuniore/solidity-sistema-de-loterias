// SPDX-License-Identifier: MIT
// msg.data (bytes): complete calldata
// msg.gas (uint): remaining gas - deprecated in version 0.4.21 and to be replaced by gasleft()
// msg.sender (address): sender of the message (current call)
// msg.sig (bytes4): first four bytes of the calldata (i.e. function identifier)
// msg.value (uint): number of wei sent with the message

pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract loteria {
    // instancia del contrato token
    ERC20Basic private token;

    // direccion
    address public owner;
    address public contrato;

    // numero de tokens creados
    uint256 totalSupply = 10000;

    constructor() public {
        // instancia funcione del contrato
        token = new ERC20Basic(totalSupply);

        // propietario que devuelve el saldo
        owner = msg.sender;

        // direccion del tokens
        contrato = address(this);
    }

    //----------------------------- TOKEN ------------------------------------------------------

    // establecer el precio de los tokens
    function PrecioToken(uint256 _numTokens) internal pure returns (uint256) {
        // conversion de tokens a ethers: 1 Token -> 1e18 Ethers
        return _numTokens * (1 ether);
    }

    // obtiene el saldo de propietario
    function getOwnerBalance() public view returns (uint256) {
        return owner.balance;
    }

    // Generar mas tokens por la loteria
    function GenerarTokens(uint256 _numTokens) public Unicamente(msg.sender) {
        token.increaseTotalSuply(_numTokens);
    }

    // este es un control para las funciones ejecutables por el profesor
    modifier Unicamente(address _direccion) {
        // requiere que el owner sea el que lo pide
        require(
            _direccion == owner,
            "No tienes permisos para ejecutar esta funcion"
        );
        _;
    }

    // comprar tokens para comprar boletos y tickert para loterias
    function ComprarTokens(uint256 _numTokens) public payable {
        // establcer el precio del token
        uint256 coste = PrecioToken(_numTokens);

        // se requiere que el valor de ether pagado se igual al precio del token
        require(msg.value >= coste, "El precio es mayor al saldo del cliente");

        // diferencia a pagar
        uint256 returnValue = msg.value - coste;

        // tranfenrencia de la diferencia
        msg.sender.transfer(returnValue);

        // obtenemos balance de token diponible
        uint256 Balance = TokensDisponible();

        // Filtro para evaluar el balance
        require(_numTokens <= Balance, "2 - No tienes suficientes tokens");

        // tranferencia de tokens al comprador
        token.transfer(msg.sender, _numTokens);
    }

    // Devuelve lo numero del token disponible del contrato para en usuario
    function balanceOfOwner() public view returns (uint256) {
        return token.balanceOf(owner);
    }

    // token disponible para la venta (Token del contrato)
    function TokensDisponible() public view returns (uint256) {
        // le pasamos la direccion del contrato
        return token.balanceOf(contrato);
    }
}
