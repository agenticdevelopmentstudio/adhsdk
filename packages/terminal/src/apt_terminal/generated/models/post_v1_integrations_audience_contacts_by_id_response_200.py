from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_audience_contacts_by_id_response_200_fields_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1,
    )
    from ..models.post_v1_integrations_audience_contacts_by_id_response_200_raw_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1,
    )
    from ..models.post_v1_integrations_audience_contacts_by_id_response_200_tags_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1,
    )


T = TypeVar("T", bound="PostV1IntegrationsAudienceContactsByIdResponse200")


@_attrs_define
class PostV1IntegrationsAudienceContactsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        connection_id (str):
        provider (str):
        audience_id (str):
        external_id (str):
        email (str):
        status (str):
        first_name (None | str):
        last_name (None | str):
        tags (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1 | str):
        fields (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1 |
            str):
        subscribed_at (None | str):
        raw (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1 | str):
        is_deleted (bool):
        deleted_at (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
        object_ (Literal['integrations.audience_contact'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    connection_id: str
    provider: str
    audience_id: str
    external_id: str
    email: str
    status: str
    first_name: None | str
    last_name: None | str
    tags: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1
        | str
    )
    fields: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1
        | str
    )
    subscribed_at: None | str
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1
        | str
    )
    is_deleted: bool
    deleted_at: None | str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str
    object_: Literal["integrations.audience_contact"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_fields_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_raw_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_tags_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        connection_id = self.connection_id

        provider = self.provider

        audience_id = self.audience_id

        external_id = self.external_id

        email = self.email

        status = self.status

        first_name: None | str
        first_name = self.first_name

        last_name: None | str
        last_name = self.last_name

        tags: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.tags, PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1):
            tags = self.tags.to_dict()
        elif isinstance(self.tags, list):
            tags = self.tags

        else:
            tags = self.tags

        fields: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(
            self.fields, PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1
        ):
            fields = self.fields.to_dict()
        elif isinstance(self.fields, list):
            fields = self.fields

        else:
            fields = self.fields

        subscribed_at: None | str
        subscribed_at = self.subscribed_at

        raw: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.raw, PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "connection_id": connection_id,
                "provider": provider,
                "audience_id": audience_id,
                "external_id": external_id,
                "email": email,
                "status": status,
                "first_name": first_name,
                "last_name": last_name,
                "tags": tags,
                "fields": fields,
                "subscribed_at": subscribed_at,
                "raw": raw,
                "is_deleted": is_deleted,
                "deleted_at": deleted_at,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
                "author_kind": author_kind,
                "author_id": author_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_fields_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_raw_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_response_200_tags_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        connection_id = d.pop("connection_id")

        provider = d.pop("provider")

        audience_id = d.pop("audience_id")

        external_id = d.pop("external_id")

        email = d.pop("email")

        status = d.pop("status")

        def _parse_first_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        first_name = _parse_first_name(d.pop("first_name"))

        def _parse_last_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_name = _parse_last_name(d.pop("last_name"))

        def _parse_tags(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                tags_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1.from_dict(data)
                )

                return tags_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                tags_type_0_type_2 = cast(list[Any], data)

                return tags_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1IntegrationsAudienceContactsByIdResponse200TagsType0Type1
                | str,
                data,
            )

        tags = _parse_tags(d.pop("tags"))

        def _parse_fields(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                fields_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1.from_dict(
                        data
                    )
                )

                return fields_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                fields_type_0_type_2 = cast(list[Any], data)

                return fields_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1IntegrationsAudienceContactsByIdResponse200FieldsType0Type1
                | str,
                data,
            )

        fields = _parse_fields(d.pop("fields"))

        def _parse_subscribed_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subscribed_at = _parse_subscribed_at(d.pop("subscribed_at"))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1.from_dict(data)
                )

                return raw_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                raw_type_0_type_2 = cast(list[Any], data)

                return raw_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1IntegrationsAudienceContactsByIdResponse200RawType0Type1
                | str,
                data,
            )

        raw = _parse_raw(d.pop("raw"))

        is_deleted = d.pop("is_deleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        object_ = cast(Literal["integrations.audience_contact"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.audience_contact" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.audience_contact', got '{object_}'"
            )

        post_v1_integrations_audience_contacts_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            connection_id=connection_id,
            provider=provider,
            audience_id=audience_id,
            external_id=external_id,
            email=email,
            status=status,
            first_name=first_name,
            last_name=last_name,
            tags=tags,
            fields=fields,
            subscribed_at=subscribed_at,
            raw=raw,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
            object_=object_,
        )

        return post_v1_integrations_audience_contacts_by_id_response_200
