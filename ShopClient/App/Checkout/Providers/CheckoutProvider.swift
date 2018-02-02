//
//  CheckoutProvider.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 2/2/18.
//  Copyright © 2018 RubyGarage. All rights reserved.
//

import UIKit

class CheckoutProvider: NSObject {
    var checkout: Checkout?
    var cartProducts: [CartProduct] = []
    var billingAddress: Address?
    var creditCard: CreditCard?
    var selectedPaymentType: PaymentType?
    var customerEmail: String?
    
    weak var delegate: CheckoutCombinedDelegate?
}

// MARK: - UITableViewDataSource

extension CheckoutProvider: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return selectedPaymentType == .creditCard ? CheckoutSection.allValues.count : CheckoutSection.valuesWithoutShippingOptions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == CheckoutSection.shippingOptions.rawValue {
            return checkout?.availableShippingRates?.count ?? 1
        } else if section == CheckoutSection.payment.rawValue {
            return selectedPaymentType == .creditCard ? PaymentAddCellType.allValues.count : 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case CheckoutSection.cart.rawValue:
            return cartCell(with: tableView, indexPath: indexPath)
        case CheckoutSection.shippingAddress.rawValue:
            return shippingAddressCell(with: tableView, indexPath: indexPath)
        case CheckoutSection.payment.rawValue:
            return paymentCell(with: tableView, indexPath: indexPath)
        case CheckoutSection.shippingOptions.rawValue:
            return shippingOptionsCell(with: tableView, indexPath: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    private func cartCell(with tableView: UITableView, indexPath: IndexPath) -> CheckoutCartTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutCartTableViewCell.self), for: indexPath) as! CheckoutCartTableViewCell
        let images = cartProducts.map({ $0.productVariant?.image ?? Image() })
        let productVariantIds = cartProducts.map({ $0.productVariant?.id ?? "" })
        cell.configure(with: images, productVariantIds: productVariantIds)
        cell.cellDelegate = delegate
        return cell
    }
    
    private func shippingAddressCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if let shippingAddress = checkout?.shippingAddress {
            return shippingAddressEditCell(with: tableView, indexPath: indexPath, address: shippingAddress)
        } else {
            return shippingAddressAddCell(with: tableView, indexPath: indexPath)
        }
    }
    
    private func shippingAddressAddCell(with tableView: UITableView, indexPath: IndexPath) -> CheckoutShippingAddressAddTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutShippingAddressAddTableCell.self), for: indexPath) as! CheckoutShippingAddressAddTableCell
        cell.delegate = delegate
        return cell
    }
    
    private func shippingAddressEditCell(with tableView: UITableView, indexPath: IndexPath, address: Address) -> CheckoutShippingAddressEditTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutShippingAddressEditTableCell.self), for: indexPath) as! CheckoutShippingAddressEditTableCell
        cell.delegate = delegate
        cell.configure(with: address)
        return cell
    }
    
    private func paymentCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case PaymentAddCellType.type.rawValue:
            return paymentTypeCell(with: tableView, indexPath: indexPath)
        case PaymentAddCellType.card.rawValue:
            return paymentCardCell(with: tableView, indexPath: indexPath)
        case PaymentAddCellType.billingAddress.rawValue:
            return paymentBillingAddressCell(with: tableView, indexPath: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    private func paymentTypeCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if let selectedType = selectedPaymentType {
            return paymentEditCell(with: tableView, indexPath: indexPath, selectedType: selectedType)
        } else {
            return paymentAddCell(with: tableView, indexPath: indexPath)
        }
    }
    
    private func paymentAddCell(with tableView: UITableView, indexPath: IndexPath) -> CheckoutPaymentAddTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutPaymentAddTableCell.self), for: indexPath) as! CheckoutPaymentAddTableCell
        cell.delegate = delegate
        let type = PaymentAddCellType(rawValue: indexPath.row)
        cell.configure(type: type!)
        return cell
    }
    
    private func paymentEditCell(with tableView: UITableView, indexPath: IndexPath, selectedType: PaymentType) -> CheckoutSelectedTypeTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutSelectedTypeTableCell.self), for: indexPath) as! CheckoutSelectedTypeTableCell
        cell.delegate = delegate
        cell.configure(type: selectedType)
        return cell
    }
    
    private func paymentCardCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if let card = creditCard {
            return paymentCardEditCell(with: tableView, indexPath: indexPath, creditCard: card)
        } else {
            return paymentAddCell(with: tableView, indexPath: indexPath)
        }
    }
    
    private func paymentCardEditCell(with tableView: UITableView, indexPath: IndexPath, creditCard: CreditCard) -> CheckoutCreditCardEditTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutCreditCardEditTableCell.self), for: indexPath) as! CheckoutCreditCardEditTableCell
        cell.delegate = delegate
        cell.configure(with: creditCard)
        return cell
    }
    
    private func paymentBillingAddressCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if let address = billingAddress {
            return paymentBillingAddressEditCell(with: tableView, indexPath: indexPath, address: address)
        } else {
            return paymentAddCell(with: tableView, indexPath: indexPath)
        }
    }
    
    private func paymentBillingAddressEditCell(with tableView: UITableView, indexPath: IndexPath, address: Address) -> CheckoutBillingAddressEditTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutBillingAddressEditTableCell.self), for: indexPath) as! CheckoutBillingAddressEditTableCell
        cell.delegate = delegate
        cell.configure(with: address)
        return cell
    }
    
    private func shippingOptionsCell(with tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if checkout?.shippingAddress != nil, let rates = checkout?.availableShippingRates, let currencyCode = checkout?.currencyCode {
            let rate = rates[indexPath.row]
            let selected = checkout?.shippingLine?.handle == rate.handle
            return shippingOptionsEnabledCell(with: tableView, indexPath: indexPath, rate: rate, currencyCode: currencyCode, selected: selected)
        } else {
            return shippingOptionsDisabledCell(with: tableView, indexPath: indexPath)
        }
    }
    
    private func shippingOptionsEnabledCell(with tableView: UITableView, indexPath: IndexPath, rate: ShippingRate, currencyCode: String, selected: Bool) -> CheckoutShippingOptionsEnabledTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutShippingOptionsEnabledTableCell.self), for: indexPath) as! CheckoutShippingOptionsEnabledTableCell
        cell.delegate = delegate
        cell.configure(with: rate, currencyCode: currencyCode, selected: selected)
        return cell
    }
    
    private func shippingOptionsDisabledCell(with tableView: UITableView, indexPath: IndexPath) -> CheckoutShippingOptionsDisabledTableCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: CheckoutShippingOptionsDisabledTableCell.self), for: indexPath) as! CheckoutShippingOptionsDisabledTableCell
    }
}

// MARK: - UITableViewDelegate

extension CheckoutProvider: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if checkout != nil, section == CheckoutSection.shippingOptions.rawValue {
            return PaymentDetailsFooterView.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case CheckoutSection.cart.rawValue:
            let view = SeeAllTableHeaderView(type: .myCart, separatorVisible: true)
            view.hideSeeAllButton()
            return view
        case CheckoutSection.shippingAddress.rawValue:
            return BoldTitleTableHeaderView(type: .shippingAddress)
        case CheckoutSection.payment.rawValue:
            return BoldTitleTableHeaderView(type: .payment)
        case CheckoutSection.shippingOptions.rawValue:
            let disabled = checkout?.availableShippingRates == nil
            return BoldTitleTableHeaderView(type: .shippingOptions, disabled: disabled)
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let checkout = checkout, section == CheckoutSection.shippingOptions.rawValue {
            return PaymentDetailsFooterView(checkout: checkout)
        }
        return nil
    }
}
