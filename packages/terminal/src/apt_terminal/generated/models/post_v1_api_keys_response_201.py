from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ApiKeysResponse201")


@_attrs_define
class PostV1ApiKeysResponse201:
    """
    Attributes:
        id (str):
        name (str):
        prefix (str): Non-secret leading chars, for display
        created (int): Unix timestamp, in seconds.
        expires_at (None | str):
        last_used_at (None | str):
        token (str): The raw token value — shown exactly once
        scope (list[str] | None | Unset): REST path prefixes this token may reach (e.g. ["/content/markdown"], optional
            ":read" suffix, "*" = all). null = legacy curated-only.
        object_ (Literal['api_key'] | Unset):
    """

    id: str
    name: str
    prefix: str
    created: int
    expires_at: None | str
    last_used_at: None | str
    token: str
    scope: list[str] | None | Unset = UNSET
    object_: Literal["api_key"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        prefix = self.prefix

        created = self.created

        expires_at: None | str
        expires_at = self.expires_at

        last_used_at: None | str
        last_used_at = self.last_used_at

        token = self.token

        scope: list[str] | None | Unset
        if isinstance(self.scope, Unset):
            scope = UNSET
        elif isinstance(self.scope, list):
            scope = self.scope

        else:
            scope = self.scope

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "prefix": prefix,
                "created": created,
                "expires_at": expires_at,
                "last_used_at": last_used_at,
                "token": token,
            }
        )
        if scope is not UNSET:
            field_dict["scope"] = scope
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        prefix = d.pop("prefix")

        created = d.pop("created")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expires_at"))

        def _parse_last_used_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_used_at = _parse_last_used_at(d.pop("last_used_at"))

        token = d.pop("token")

        def _parse_scope(data: object) -> list[str] | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                scope_type_0 = cast(list[str], data)

                return scope_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[str] | None | Unset, data)

        scope = _parse_scope(d.pop("scope", UNSET))

        object_ = cast(Literal["api_key"] | Unset, d.pop("object", UNSET))
        if object_ != "api_key" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'api_key', got '{object_}'")

        post_v1_api_keys_response_201 = cls(
            id=id,
            name=name,
            prefix=prefix,
            created=created,
            expires_at=expires_at,
            last_used_at=last_used_at,
            token=token,
            scope=scope,
            object_=object_,
        )

        post_v1_api_keys_response_201.additional_properties = d
        return post_v1_api_keys_response_201

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
