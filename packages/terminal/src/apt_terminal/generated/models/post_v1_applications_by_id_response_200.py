from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.application_client_auth import ApplicationClientAuth


T = TypeVar("T", bound="PostV1ApplicationsByIdResponse200")


@_attrs_define
class PostV1ApplicationsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        slug (str):
        display_name (str):
        consumer_kind (str):
        platform (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['application'] | Unset):
        client_auth (ApplicationClientAuth | Unset): An application's client auth. The ecosystem's policy governs every
            sign-in; `registration` null means the application signs in through the ecosystem's registration.
        schema_grants (Any | Unset):
    """

    id: str
    ecosystem_id: str
    slug: str
    display_name: str
    consumer_kind: str
    platform: str
    created: int
    updated: int
    is_deleted: bool
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["application"] | Unset = UNSET
    client_auth: ApplicationClientAuth | Unset = UNSET
    schema_grants: Any | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        slug = self.slug

        display_name = self.display_name

        consumer_kind = self.consumer_kind

        platform = self.platform

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        client_auth: dict[str, Any] | Unset = UNSET
        if not isinstance(self.client_auth, Unset):
            client_auth = self.client_auth.to_dict()

        schema_grants = self.schema_grants

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "slug": slug,
                "display_name": display_name,
                "consumer_kind": consumer_kind,
                "platform": platform,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "deleted_at": deleted_at,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if client_auth is not UNSET:
            field_dict["client_auth"] = client_auth
        if schema_grants is not UNSET:
            field_dict["schema_grants"] = schema_grants

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.application_client_auth import ApplicationClientAuth

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        slug = d.pop("slug")

        display_name = d.pop("display_name")

        consumer_kind = d.pop("consumer_kind")

        platform = d.pop("platform")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["application"] | Unset, d.pop("object", UNSET))
        if object_ != "application" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'application', got '{object_}'")

        _client_auth = d.pop("client_auth", UNSET)
        client_auth: ApplicationClientAuth | Unset
        if isinstance(_client_auth, Unset):
            client_auth = UNSET
        else:
            client_auth = ApplicationClientAuth.from_dict(_client_auth)

        schema_grants = d.pop("schema_grants", UNSET)

        post_v1_applications_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            slug=slug,
            display_name=display_name,
            consumer_kind=consumer_kind,
            platform=platform,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
            client_auth=client_auth,
            schema_grants=schema_grants,
        )

        post_v1_applications_by_id_response_200.additional_properties = d
        return post_v1_applications_by_id_response_200

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
