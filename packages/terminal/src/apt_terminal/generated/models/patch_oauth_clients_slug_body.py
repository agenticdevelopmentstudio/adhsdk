from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchOauthClientsSlugBody")


@_attrs_define
class PatchOauthClientsSlugBody:
    """
    Attributes:
        slug (str):
        name (str):
        default_ecosystem_id (str):
        allowed_return_origins (list[str] | Unset):
        jwt_audience (None | str | Unset):
    """

    slug: str
    name: str
    default_ecosystem_id: str
    allowed_return_origins: list[str] | Unset = UNSET
    jwt_audience: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        default_ecosystem_id = self.default_ecosystem_id

        allowed_return_origins: list[str] | Unset = UNSET
        if not isinstance(self.allowed_return_origins, Unset):
            allowed_return_origins = self.allowed_return_origins

        jwt_audience: None | str | Unset
        if isinstance(self.jwt_audience, Unset):
            jwt_audience = UNSET
        else:
            jwt_audience = self.jwt_audience

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "defaultEcosystemId": default_ecosystem_id,
            }
        )
        if allowed_return_origins is not UNSET:
            field_dict["allowedReturnOrigins"] = allowed_return_origins
        if jwt_audience is not UNSET:
            field_dict["jwtAudience"] = jwt_audience

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        default_ecosystem_id = d.pop("defaultEcosystemId")

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins", UNSET))

        def _parse_jwt_audience(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        jwt_audience = _parse_jwt_audience(d.pop("jwtAudience", UNSET))

        patch_oauth_clients_slug_body = cls(
            slug=slug,
            name=name,
            default_ecosystem_id=default_ecosystem_id,
            allowed_return_origins=allowed_return_origins,
            jwt_audience=jwt_audience,
        )

        patch_oauth_clients_slug_body.additional_properties = d
        return patch_oauth_clients_slug_body

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
