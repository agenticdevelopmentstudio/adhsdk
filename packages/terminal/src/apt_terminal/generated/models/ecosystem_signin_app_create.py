from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="EcosystemSigninAppCreate")


@_attrs_define
class EcosystemSigninAppCreate:
    """
    Attributes:
        slug (str): The LEAF only — the stored slug is "<ecosystem-slug>.<this>", composed by the server. A composed
            slug over 100 characters is a 400.
        name (str):
        allowed_return_origins (list[str] | Unset): Bare http(s) origins: no credentials, no path, no query, no
            fragment. Anything else is a 400.
        enable_github (bool | Unset):  Default: True.
    """

    slug: str
    name: str
    allowed_return_origins: list[str] | Unset = UNSET
    enable_github: bool | Unset = True
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        allowed_return_origins: list[str] | Unset = UNSET
        if not isinstance(self.allowed_return_origins, Unset):
            allowed_return_origins = self.allowed_return_origins

        enable_github = self.enable_github

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if allowed_return_origins is not UNSET:
            field_dict["allowedReturnOrigins"] = allowed_return_origins
        if enable_github is not UNSET:
            field_dict["enableGithub"] = enable_github

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins", UNSET))

        enable_github = d.pop("enableGithub", UNSET)

        ecosystem_signin_app_create = cls(
            slug=slug,
            name=name,
            allowed_return_origins=allowed_return_origins,
            enable_github=enable_github,
        )

        ecosystem_signin_app_create.additional_properties = d
        return ecosystem_signin_app_create

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
