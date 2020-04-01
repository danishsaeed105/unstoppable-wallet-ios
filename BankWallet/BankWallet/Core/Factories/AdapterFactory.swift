class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let blockchainSettingsManager: IBlockchainSettingsManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager, blockchainSettingsManager: IBlockchainSettingsManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
        self.blockchainSettingsManager = blockchainSettingsManager
        self.derivationSettingsManager = derivationSettingsManager
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        let settings = blockchainSettingsManager.settings(coinType: wallet.coin.type)
        let derivation = (try? derivationSettingsManager.derivationSetting(coinType: wallet.coin.type))?.derivation

        switch wallet.coin.type {
        case .bitcoin:
            return try? BitcoinAdapter(wallet: wallet, settings: settings, derivation: derivation, testMode: appConfigProvider.testMode)
        case .litecoin:
            return try? LitecoinAdapter(wallet: wallet, settings: settings, derivation: derivation, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return try? BitcoinCashAdapter(wallet: wallet, settings: settings, testMode: appConfigProvider.testMode)
        case .dash:
            return try? DashAdapter(wallet: wallet, settings: settings, testMode: appConfigProvider.testMode)
        case .ethereum:
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return EthereumAdapter(ethereumKit: ethereumKit)
            }
        case let .erc20(address, fee, gasLimit, minimumRequiredBalance, minimumSpendableAmount):
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return try? Erc20Adapter(ethereumKit: ethereumKit, contractAddress: address, decimal: wallet.coin.decimal, fee: fee, gasLimit: gasLimit, minimumRequiredBalance: minimumRequiredBalance, minimumSpendableAmount: minimumSpendableAmount)
            }
        case let .eos(token, symbol):
            if let eosKit = try? eosKitManager.eosKit(account: wallet.account) {
                return EosAdapter(eosKit: eosKit, token: token, symbol: symbol, decimal: wallet.coin.decimal)
            }
        case let .binance(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account) {
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol)
            }
        }

        return nil
    }

}
