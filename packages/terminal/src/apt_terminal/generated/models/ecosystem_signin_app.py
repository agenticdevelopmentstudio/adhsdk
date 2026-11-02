from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="EcosystemSigninApp")


@_attrs_define
class EcosystemSigninApp:
    """An OAuth client that signs users into this ecosystem. The app token is represented by its non-secret prefix only —
    the secret itself is never part of this shape.

        Attributes:
            id (str):
            slug (str): The full client slug, composed server-side as "<ecosystem>.<leaf>"
            name (str):
            allowed_return_origins (list[str]):
            default_ecosystem_id (str):
            jwt_audience (None | str):
            is_internal (bool): Always false here — internal clients are not listed or editable
            app_token_prefix (None | str):
            github_enabled (bool):
    """

    id: str
    slug: str
    name: str
    allowed_return_origins: list[str]
    default_ecosystem_id: str
    jwt_audience: None | str
    is_internal: bool
    app_token_prefix: None | str
    github_enabled: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        allowed_return_origins = self.allowed_return_origins

        default_ecosystem_id = self.default_ecosystem_id

        jwt_audience: None | str
        jwt_audience = self.jwt_audience

        is_internal = self.is_internal

        app_token_prefix: None | str
        app_token_prefix = self.app_token_prefix

        github_enabled = self.github_enabled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "allowedReturnOrigins": allowed_return_origins,
                "defaultEcosystemId": default_ecosystem_id,
                "jwtAudience": jwt_audience,
                "isInternal": is_internal,
                "appTokenPrefix": app_token_prefix,
                "githubEnabled": github_enabled,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins"))

        default_ecosystem_id = d.pop("defaultEcosystemId")

        def _parse_jwt_audience(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        jwt_audience = _parse_jwt_audience(d.pop("jwtAudience"))

        is_internal = d.pop("isInternal")

        def _parse_app_token_prefix(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        app_token_prefix = _parse_app_token_prefix(d.pop("appTokenPrefix"))

        github_enabled = d.pop("githubEnabled")

        ecosystem_signin_app = cls(
            id=id,
            slug=slug,
            name=name,
            allowed_return_origins=allowed_return_origins,
            default_ecosystem_id=default_ecosystem_id,
            jwt_audience=jwt_audience,
            is_internal=is_internal,
            app_token_prefix=app_token_prefix,
            github_enabled=github_enabled,
        )

        ecosystem_signin_app.additional_properties = d
        return ecosystem_signin_app

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
