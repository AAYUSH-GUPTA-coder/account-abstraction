// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() external {}

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config)
        public
        returns (PackedUserOperation memory)
    {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, config.account, nonce);

        // 2. Get the userOp Hash

        // Generate a request Id - unique identifier for this request.
        // The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        // Returns the keccak256 digest of an EIP-191 signed data with version`0x45`
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign it and return it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_PUBLIC_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_PUBLIC_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); // Note the order
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
