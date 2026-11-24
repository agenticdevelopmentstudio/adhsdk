from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ecosystem_auth_settings import EcosystemAuthSettings
    from ..models.ecosystem_client_auth import EcosystemClientAuth


T = TypeVar("T", bound="GetV1EcosystemsByIdResponse200")


@_attrs_define
class GetV1EcosystemsByIdResponse200:
    """
    Attributes:
        id (str):
        owner_id (str):
        owner_kind (None | str):
        slug (str):
        name (str):
        description (str):
        region (str):
        dedicated_db_connection_id (None | str):
        primary_domain (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        is_default (bool):
        type_ (str):
        namespace_id (None | str):
        parent_id (None | str):
        archived_at (None | str):
        is_infrastructure (bool): Whether this is a principal's own ecosystem: true exactly when `type` is `workspace`
            or `persona`. Derived from `type`; read `type` instead.
        object_ (Literal['ecosystem'] | Unset):
        auth_settings (EcosystemAuthSettings | Unset): An ecosystem's sign-up and sign-in policy. Defaults are returned
            when nothing has been set.
        client_auth (EcosystemClientAuth | Unset): An ecosystem's client auth: its policy, its own login registration,
            the providers.
    """

    id: str
    owner_id: str
    owner_kind: None | str
    slug: str
    name: str
    description: str
    region: str
    dedicated_db_connection_id: None | str
    primary_domain: str
    created: int
    updated: int
    is_deleted: bool
    is_default: bool
    type_: str
    namespace_id: None | str
    parent_id: None | str
    archived_at: None | str
    is_infrastructure: bool
    object_: Literal["ecosystem"] | Unset = UNSET
    auth_settings: EcosystemAuthSettings | Unset = UNSET
    client_auth: EcosystemClientAuth | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_id = self.owner_id

        owner_kind: None | str
        owner_kind = self.owner_kind

        slug = self.slug

        name = self.name

        description = self.description

        region = self.region

        dedicated_db_connection_id: None | str
        dedicated_db_connection_id = self.dedicated_db_connection_id

        primary_domain = self.primary_domain

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        is_default = self.is_default

        type_ = self.type_

        namespace_id: None | str
        namespace_id = self.namespace_id

        parent_id: None | str
        parent_id = self.parent_id

        archived_at: None | str
        archived_at = self.archived_at

        is_infrastructure = self.is_infrastructure

        object_ = self.object_

        auth_settings: dict[str, Any] | Unset = UNSET
        if not isinstance(self.auth_settings, Unset):
            auth_settings = self.auth_settings.to_dict()

        client_auth: dict[str, Any] | Unset = UNSET
        if not isinstance(self.client_auth, Unset):
            client_auth = self.client_auth.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "owner_id": owner_id,
                "owner_kind": owner_kind,
                "slug": slug,
                "name": name,
                "description": description,
                "region": region,
                "dedicated_db_connection_id": dedicated_db_connection_id,
                "primary_domain": primary_domain,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "is_default": is_default,
                "type": type_,
                "namespace_id": namespace_id,
                "parent_id": parent_id,
                "archived_at": archived_at,
                "is_infrastructure": is_infrastructure,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if auth_settings is not UNSET:
            field_dict["auth_settings"] = auth_settings
        if client_auth is not UNSET:
            field_dict["client_auth"] = client_auth

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ecosystem_auth_settings import EcosystemAuthSettings
        from ..models.ecosystem_client_auth import EcosystemClientAuth

        d = dict(src_dict)
        id = d.pop("id")

        owner_id = d.pop("owner_id")

        def _parse_owner_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        owner_kind = _parse_owner_kind(d.pop("owner_kind"))

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        region = d.pop("region")

        def _parse_dedicated_db_connection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        dedicated_db_connection_id = _parse_dedicated_db_connection_id(
            d.pop("dedicated_db_connection_id")
        )

        primary_domain = d.pop("primary_domain")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        is_default = d.pop("is_default")

        type_ = d.pop("type")

        def _parse_namespace_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        namespace_id = _parse_namespace_id(d.pop("namespace_id"))

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parent_id"))

        def _parse_archived_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        archived_at = _parse_archived_at(d.pop("archived_at"))

        is_infrastructure = d.pop("is_infrastructure")

        object_ = cast(Literal["ecosystem"] | Unset, d.pop("object", UNSET))
        if object_ != "ecosystem" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ecosystem', got '{object_}'")

        _auth_settings = d.pop("auth_settings", UNSET)
        auth_settings: EcosystemAuthSettings | Unset
        if isinstance(_auth_settings, Unset):
            auth_settings = UNSET
        else:
            auth_settings = EcosystemAuthSettings.from_dict(_auth_settings)

        _client_auth = d.pop("client_auth", UNSET)
        client_auth: EcosystemClientAuth | Unset
        if isinstance(_client_auth, Unset):
            client_auth = UNSET
        else:
            client_auth = EcosystemClientAuth.from_dict(_client_auth)

        get_v1_ecosystems_by_id_response_200 = cls(
            id=id,
            owner_id=owner_id,
            owner_kind=owner_kind,
            slug=slug,
            name=name,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            is_default=is_default,
            type_=type_,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
            is_infrastructure=is_infrastructure,
            object_=object_,
            auth_settings=auth_settings,
            client_auth=client_auth,
        )

        get_v1_ecosystems_by_id_response_200.additional_properties = d
        return get_v1_ecosystems_by_id_response_200

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
