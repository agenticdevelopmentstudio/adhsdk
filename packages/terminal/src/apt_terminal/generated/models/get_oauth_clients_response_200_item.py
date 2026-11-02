from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetOauthClientsResponse200Item")


@_attrs_define
class GetOauthClientsResponse200Item:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        allowed_return_origins (list[str]):
        is_internal (bool):
        default_ecosystem_id (None | str | Unset):
        app_token_prefix (None | str | Unset):
    """

    id: str
    slug: str
    name: str
    allowed_return_origins: list[str]
    is_internal: bool
    default_ecosystem_id: None | str | Unset = UNSET
    app_token_prefix: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        allowed_return_origins = self.allowed_return_origins

        is_internal = self.is_internal

        default_ecosystem_id: None | str | Unset
        if isinstance(self.default_ecosystem_id, Unset):
            default_ecosystem_id = UNSET
        else:
            default_ecosystem_id = self.default_ecosystem_id

        app_token_prefix: None | str | Unset
        if isinstance(self.app_token_prefix, Unset):
            app_token_prefix = UNSET
        else:
            app_token_prefix = self.app_token_prefix

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "allowedReturnOrigins": allowed_return_origins,
                "isInternal": is_internal,
            }
        )
        if default_ecosystem_id is not UNSET:
            field_dict["defaultEcosystemId"] = default_ecosystem_id
        if app_token_prefix is not UNSET:
            field_dict["appTokenPrefix"] = app_token_prefix

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins"))

        is_internal = d.pop("isInternal")

        def _parse_default_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        default_ecosystem_id = _parse_default_ecosystem_id(d.pop("defaultEcosystemId", UNSET))

        def _parse_app_token_prefix(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        app_token_prefix = _parse_app_token_prefix(d.pop("appTokenPrefix", UNSET))

        get_oauth_clients_response_200_item = cls(
            id=id,
            slug=slug,
            name=name,
            allowed_return_origins=allowed_return_origins,
            is_internal=is_internal,
            default_ecosystem_id=default_ecosystem_id,
            app_token_prefix=app_token_prefix,
        )

        get_oauth_clients_response_200_item.additional_properties = d
        return get_oauth_clients_response_200_item

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
