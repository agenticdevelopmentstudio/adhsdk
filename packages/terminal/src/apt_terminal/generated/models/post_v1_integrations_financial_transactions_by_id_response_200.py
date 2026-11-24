from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsFinancialTransactionsByIdResponse200")


@_attrs_define
class PostV1IntegrationsFinancialTransactionsByIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['integrations.financial_transaction'] | Unset):
    """

    id: str
    owner_kind: str
    owner_id: str
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
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["integrations.financial_transaction"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

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

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "connection_id": connection_id,
                "external_id": external_id,
                "account_id": account_id,
                "account_name": account_name,
                "institution_name": institution_name,
                "amount": amount,
                "currency": currency,
                "name": name,
                "merchant_name": merchant_name,
                "category": category,
                "category_detailed": category_detailed,
                "transaction_date": transaction_date,
                "authorized_date": authorized_date,
                "pending": pending,
                "logo_url": logo_url,
                "is_deleted": is_deleted,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        connection_id = d.pop("connection_id")

        external_id = d.pop("external_id")

        account_id = d.pop("account_id")

        def _parse_account_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        account_name = _parse_account_name(d.pop("account_name"))

        def _parse_institution_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        institution_name = _parse_institution_name(d.pop("institution_name"))

        amount = d.pop("amount")

        currency = d.pop("currency")

        name = d.pop("name")

        def _parse_merchant_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        merchant_name = _parse_merchant_name(d.pop("merchant_name"))

        def _parse_category(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category = _parse_category(d.pop("category"))

        def _parse_category_detailed(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category_detailed = _parse_category_detailed(d.pop("category_detailed"))

        transaction_date = d.pop("transaction_date")

        def _parse_authorized_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        authorized_date = _parse_authorized_date(d.pop("authorized_date"))

        pending = d.pop("pending")

        def _parse_logo_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        logo_url = _parse_logo_url(d.pop("logo_url"))

        is_deleted = d.pop("is_deleted")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(
            Literal["integrations.financial_transaction"] | Unset, d.pop("object", UNSET)
        )
        if object_ != "integrations.financial_transaction" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.financial_transaction', got '{object_}'"
            )

        post_v1_integrations_financial_transactions_by_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
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
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_integrations_financial_transactions_by_id_response_200
