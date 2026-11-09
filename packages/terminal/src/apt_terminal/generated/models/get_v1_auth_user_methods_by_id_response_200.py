from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AuthUserMethodsByIdResponse200")


@_attrs_define
class GetV1AuthUserMethodsByIdResponse200:
    """
    Attributes:
        id (str):
        user_id (str):
        provider (str):
        provider_id (None | str):
        has_credential (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['auth.user_method'] | Unset):
    """

    id: str
    user_id: str
    provider: str
    provider_id: None | str
    has_credential: bool
    created: int
    updated: int
    object_: Literal["auth.user_method"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        user_id = self.user_id

        provider = self.provider

        provider_id: None | str
        provider_id = self.provider_id

        has_credential = self.has_credential

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "user_id": user_id,
                "provider": provider,
                "provider_id": provider_id,
                "has_credential": has_credential,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        user_id = d.pop("user_id")

        provider = d.pop("provider")

        def _parse_provider_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        provider_id = _parse_provider_id(d.pop("provider_id"))

        has_credential = d.pop("has_credential")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["auth.user_method"] | Unset, d.pop("object", UNSET))
        if object_ != "auth.user_method" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'auth.user_method', got '{object_}'")

        get_v1_auth_user_methods_by_id_response_200 = cls(
            id=id,
            user_id=user_id,
            provider=provider,
            provider_id=provider_id,
            has_credential=has_credential,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_auth_user_methods_by_id_response_200.additional_properties = d
        return get_v1_auth_user_methods_by_id_response_200

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
