-include .env
deploy:
ifeq ($(ARG),polygon-pos)
	forge script script/DeployAlieMINI.s.sol:Deploy__AlieMINI --rpc-url $(POLYGON_POS_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(POLYGONSCAN_APY_KEY) -vvvv
endif
ifeq ($(ARG),sepolia)
	forge script script/DeployAlieMINI.s.sol:Deploy__AlieMINI --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif
ifeq ($(ARG),mumbai)
	forge script script/DeployAlieMINI.s.sol:Deploy__AlieMINI --rpc-url $(MUMBAI_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(POLYGONSCAN_APY_KEY) -vvvv
endif

.PHONY: deploy-sepolia deploy-mumbai


deploy-polygon-pos:
	$(MAKE) deploy ARG=polygon-pos

deploy-sepolia:
	$(MAKE) deploy ARG=sepolia

deploy-mumbai:
	$(MAKE) deploy ARG=mumbai


