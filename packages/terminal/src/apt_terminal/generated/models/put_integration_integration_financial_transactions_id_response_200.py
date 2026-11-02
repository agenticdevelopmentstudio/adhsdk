from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutIntegrationIntegrationFinancialTransactionsIdResponse200")


@_attrs_define
class PutIntegrationIntegrationFinancialTransactionsIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        account_id (str):
        account_name (None | str):
        institution_name (None | str):
        amount (str):
        currency (str):
        name (str):
        merchant_name (None | str):
        category (None | str):
        category_detailed (None | str):
        transaction_date (str):
        authorized_date (None | str):
        pending (bool):
        logo_url (None | str):
        is_deleted (bool):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    connection_id: str
    external_id: str
    account_id: str
    account_name: None | str
    institution_name: None | str
    amount: str
    currency: str
    name: str
    merchant_name: None | str
    category: None | str
    category_detailed: None | str
    transaction_date: str
    authorized_date: None | str
    pending: bool
    logo_url: None | str
    is_deleted: bool
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        account_id = self.account_id

        account_name: None | str
        account_name = self.account_name

        institution_name: None | str
        institution_name = self.institution_name

        amount = self.amount

        currency = self.currency

        name = self.name

        merchant_name: None | str
        merchant_name = self.merchant_name

        category: None | str
        category = self.category

        category_detailed: None | str
        category_detailed = self.category_detailed

        transaction_date = self.transaction_date

        authorized_date: None | str
        authorized_date = self.authorized_date

        pending = self.pending

        logo_url: None | str
        logo_url = self.logo_url

        is_deleted = self.is_deleted

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "connectionId": connection_id,
                "externalId": external_id,
                "accountId": account_id,
                "accountName": account_name,
                "institutionName": institution_name,
                "amount": amount,
                "currency": currency,
                "name": name,
                "merchantName": merchant_name,
                "category": category,
                "categoryDetailed": category_detailed,
                "transactionDate": transaction_date,
                "authorizedDate": authorized_date,
                "pending": pending,
                "logoUrl": logo_url,
                "isDeleted": is_deleted,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        connection_id = d.pop("connectionId")

        external_id = d.pop("externalId")

        account_id = d.pop("accountId")

        def _parse_account_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        account_name = _parse_account_name(d.pop("accountName"))

        def _parse_institution_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        institution_name = _parse_institution_name(d.pop("institutionName"))

        amount = d.pop("amount")

        currency = d.pop("currency")

        name = d.pop("name")

        def _parse_merchant_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        merchant_name = _parse_merchant_name(d.pop("merchantName"))

        def _parse_category(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category = _parse_category(d.pop("category"))

        def _parse_category_detailed(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category_detailed = _parse_category_detailed(d.pop("categoryDetailed"))

        transaction_date = d.pop("transactionDate")

        def _parse_authorized_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        authorized_date = _parse_authorized_date(d.pop("authorizedDate"))

        pending = d.pop("pending")

        def _parse_logo_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        logo_url = _parse_logo_url(d.pop("logoUrl"))

        is_deleted = d.pop("isDeleted")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        put_integration_integration_financial_transactions_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
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
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return put_integration_integration_financial_transactions_id_response_200
