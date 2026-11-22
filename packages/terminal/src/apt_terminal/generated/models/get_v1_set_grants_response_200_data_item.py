from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.set_grant_source import SetGrantSource
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SetGrantsResponse200DataItem")


@_attrs_define
class GetV1SetGrantsResponse200DataItem:
    """
    Attributes:
        id (UUID):
        ecosystem_id (UUID):
        owner_id (UUID): The customer.
        set_id (UUID):
        source (SetGrantSource):
        billing_account_id (None | UUID):
        granted_by (str):
        granted_at (datetime.datetime):
        revoked_at (datetime.datetime | None):
        revoke_reason (None | str): e.g. `direct`, `refund`, `offer_changed`, `purchase_conflict`.
        object_ (Literal['set_grant'] | Unset):
    """

    id: UUID
    ecosystem_id: UUID
    owner_id: UUID
    set_id: UUID
    source: SetGrantSource
    billing_account_id: None | UUID
    granted_by: str
    granted_at: datetime.datetime
    revoked_at: datetime.datetime | None
    revoke_reason: None | str
    object_: Literal["set_grant"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = str(self.ecosystem_id)

        owner_id = str(self.owner_id)

        set_id = str(self.set_id)

        source = self.source.value

        billing_account_id: None | str
        if isinstance(self.billing_account_id, UUID):
            billing_account_id = str(self.billing_account_id)
        else:
            billing_account_id = self.billing_account_id

        granted_by = self.granted_by

        granted_at = self.granted_at.isoformat()

        revoked_at: None | str
        if isinstance(self.revoked_at, datetime.datetime):
            revoked_at = self.revoked_at.isoformat()
        else:
            revoked_at = self.revoked_at

        revoke_reason: None | str
        revoke_reason = self.revoke_reason

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_id": owner_id,
                "set_id": set_id,
                "source": source,
                "billing_account_id": billing_account_id,
                "granted_by": granted_by,
                "granted_at": granted_at,
                "revoked_at": revoked_at,
                "revoke_reason": revoke_reason,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = UUID(d.pop("ecosystem_id"))

        owner_id = UUID(d.pop("owner_id"))

        set_id = UUID(d.pop("set_id"))

        source = SetGrantSource(d.pop("source"))

        def _parse_billing_account_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                billing_account_id_type_0 = UUID(data)

                return billing_account_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        billing_account_id = _parse_billing_account_id(d.pop("billing_account_id"))

        granted_by = d.pop("granted_by")

        granted_at = datetime.datetime.fromisoformat(d.pop("granted_at"))

        def _parse_revoked_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                revoked_at_type_0 = datetime.datetime.fromisoformat(data)

                return revoked_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        revoked_at = _parse_revoked_at(d.pop("revoked_at"))

        def _parse_revoke_reason(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        revoke_reason = _parse_revoke_reason(d.pop("revoke_reason"))

        object_ = cast(Literal["set_grant"] | Unset, d.pop("object", UNSET))
        if object_ != "set_grant" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'set_grant', got '{object_}'")

        get_v1_set_grants_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_id=owner_id,
            set_id=set_id,
            source=source,
            billing_account_id=billing_account_id,
            granted_by=granted_by,
            granted_at=granted_at,
            revoked_at=revoked_at,
            revoke_reason=revoke_reason,
            object_=object_,
        )

        get_v1_set_grants_response_200_data_item.additional_properties = d
        return get_v1_set_grants_response_200_data_item

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
