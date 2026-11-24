from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1EcosystemsByIdSigninAppsByClientIdResponse200")


@_attrs_define
class PostV1EcosystemsByIdSigninAppsByClientIdResponse200:
    """
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
        redirect_uris (list[str]): The OAuth redirect URIs registered on the app’s Hydra client. Empty when Hydra is
            unreachable or not configured (the list never fails on Hydra).
        object_ (Literal['signin_app'] | Unset):
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
    redirect_uris: list[str]
    object_: Literal["signin_app"] | Unset = UNSET
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

        redirect_uris = self.redirect_uris

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "allowed_return_origins": allowed_return_origins,
                "default_ecosystem_id": default_ecosystem_id,
                "jwt_audience": jwt_audience,
                "is_internal": is_internal,
                "app_token_prefix": app_token_prefix,
                "github_enabled": github_enabled,
                "redirect_uris": redirect_uris,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        allowed_return_origins = cast(list[str], d.pop("allowed_return_origins"))

        default_ecosystem_id = d.pop("default_ecosystem_id")

        def _parse_jwt_audience(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        jwt_audience = _parse_jwt_audience(d.pop("jwt_audience"))

        is_internal = d.pop("is_internal")

        def _parse_app_token_prefix(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        app_token_prefix = _parse_app_token_prefix(d.pop("app_token_prefix"))

        github_enabled = d.pop("github_enabled")

        redirect_uris = cast(list[str], d.pop("redirect_uris"))

        object_ = cast(Literal["signin_app"] | Unset, d.pop("object", UNSET))
        if object_ != "signin_app" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'signin_app', got '{object_}'")

        post_v1_ecosystems_by_id_signin_apps_by_client_id_response_200 = cls(
            id=id,
            slug=slug,
            name=name,
            allowed_return_origins=allowed_return_origins,
            default_ecosystem_id=default_ecosystem_id,
            jwt_audience=jwt_audience,
            is_internal=is_internal,
            app_token_prefix=app_token_prefix,
            github_enabled=github_enabled,
            redirect_uris=redirect_uris,
            object_=object_,
        )

        post_v1_ecosystems_by_id_signin_apps_by_client_id_response_200.additional_properties = d
        return post_v1_ecosystems_by_id_signin_apps_by_client_id_response_200

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
