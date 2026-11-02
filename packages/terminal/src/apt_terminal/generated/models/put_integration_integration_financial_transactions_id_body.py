from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutIntegrationIntegrationFinancialTransactionsIdBody")


@_attrs_define
class PutIntegrationIntegrationFinancialTransactionsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        connection_id (str | Unset):
        external_id (str | Unset):
        account_id (str | Unset):
        account_name (None | str | Unset):
        institution_name (None | str | Unset):
        amount (str | Unset):
        currency (str | Unset):
        name (str | Unset):
        merchant_name (None | str | Unset):
        category (None | str | Unset):
        category_detailed (None | str | Unset):
        transaction_date (str | Unset):
        authorized_date (None | str | Unset):
        pending (bool | Unset):
        logo_url (None | str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    connection_id: str | Unset = UNSET
    external_id: str | Unset = UNSET
    account_id: str | Unset = UNSET
    account_name: None | str | Unset = UNSET
    institution_name: None | str | Unset = UNSET
    amount: str | Unset = UNSET
    currency: str | Unset = UNSET
    name: str | Unset = UNSET
    merchant_name: None | str | Unset = UNSET
    category: None | str | Unset = UNSET
    category_detailed: None | str | Unset = UNSET
    transaction_date: str | Unset = UNSET
    authorized_date: None | str | Unset = UNSET
    pending: bool | Unset = UNSET
    logo_url: None | str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        account_id = self.account_id

        account_name: None | str | Unset
        if isinstance(self.account_name, Unset):
            account_name = UNSET
        else:
            account_name = self.account_name

        institution_name: None | str | Unset
        if isinstance(self.institution_name, Unset):
            institution_name = UNSET
        else:
            institution_name = self.institution_name

        amount = self.amount

        currency = self.currency

        name = self.name

        merchant_name: None | str | Unset
        if isinstance(self.merchant_name, Unset):
            merchant_name = UNSET
        else:
            merchant_name = self.merchant_name

        category: None | str | Unset
        if isinstance(self.category, Unset):
            category = UNSET
        else:
            category = self.category

        category_detailed: None | str | Unset
        if isinstance(self.category_detailed, Unset):
            category_detailed = UNSET
        else:
            category_detailed = self.category_detailed

        transaction_date = self.transaction_date

        authorized_date: None | str | Unset
        if isinstance(self.authorized_date, Unset):
            authorized_date = UNSET
        else:
            authorized_date = self.authorized_date

        pending = self.pending

        logo_url: None | str | Unset
        if isinstance(self.logo_url, Unset):
            logo_url = UNSET
        else:
            logo_url = self.logo_url

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if connection_id is not UNSET:
            field_dict["connectionId"] = connection_id
        if external_id is not UNSET:
            field_dict["externalId"] = external_id
        if account_id is not UNSET:
            field_dict["accountId"] = account_id
        if account_name is not UNSET:
            field_dict["accountName"] = account_name
        if institution_name is not UNSET:
            field_dict["institutionName"] = institution_name
        if amount is not UNSET:
            field_dict["amount"] = amount
        if currency is not UNSET:
            field_dict["currency"] = currency
        if name is not UNSET:
            field_dict["name"] = name
        if merchant_name is not UNSET:
            field_dict["merchantName"] = merchant_name
        if category is not UNSET:
            field_dict["category"] = category
        if category_detailed is not UNSET:
            field_dict["categoryDetailed"] = category_detailed
        if transaction_date is not UNSET:
            field_dict["transactionDate"] = transaction_date
        if authorized_date is not UNSET:
            field_dict["authorizedDate"] = authorized_date
        if pending is not UNSET:
            field_dict["pending"] = pending
        if logo_url is not UNSET:
            field_dict["logoUrl"] = logo_url
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        connection_id = d.pop("connectionId", UNSET)

        external_id = d.pop("externalId", UNSET)

        account_id = d.pop("accountId", UNSET)

        def _parse_account_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        account_name = _parse_account_name(d.pop("accountName", UNSET))

        def _parse_institution_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        institution_name = _parse_institution_name(d.pop("institutionName", UNSET))

        amount = d.pop("amount", UNSET)

        currency = d.pop("currency", UNSET)

        name = d.pop("name", UNSET)

        def _parse_merchant_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        merchant_name = _parse_merchant_name(d.pop("merchantName", UNSET))

        def _parse_category(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category = _parse_category(d.pop("category", UNSET))

        def _parse_category_detailed(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category_detailed = _parse_category_detailed(d.pop("categoryDetailed", UNSET))

        transaction_date = d.pop("transactionDate", UNSET)

        def _parse_authorized_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        authorized_date = _parse_authorized_date(d.pop("authorizedDate", UNSET))

        pending = d.pop("pending", UNSET)

        def _parse_logo_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        logo_url = _parse_logo_url(d.pop("logoUrl", UNSET))

        sync_txid = d.pop("syncTxid", UNSET)

        put_integration_integration_financial_transactions_id_body = cls(
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            account_id=account_id,
            account_name=account_name,
            institution_name=institution_name,
            amount=amount,
            currency=currency,
            name=name,
            merchant_name=merchant_name,
            category=category,
            category_detailed=category_detailed,
            transaction_date=transaction_date,
            authorized_date=authorized_date,
            pending=pending,
            logo_url=logo_url,
            sync_txid=sync_txid,
        )

        return put_integration_integration_financial_transactions_id_body
