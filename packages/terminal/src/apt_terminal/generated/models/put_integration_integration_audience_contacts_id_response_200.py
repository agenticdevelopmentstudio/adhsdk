from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.put_integration_integration_audience_contacts_id_response_200_fields_type_0_type_1 import (
        PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1,
    )
    from ..models.put_integration_integration_audience_contacts_id_response_200_raw_type_0_type_1 import (
        PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1,
    )
    from ..models.put_integration_integration_audience_contacts_id_response_200_tags_type_0_type_1 import (
        PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1,
    )


T = TypeVar("T", bound="PutIntegrationIntegrationAudienceContactsIdResponse200")


@_attrs_define
class PutIntegrationIntegrationAudienceContactsIdResponse200:
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
        tags (bool | float | list[Any] | None | PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1 |
            str):
        fields (bool | float | list[Any] | None | PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1
            | str):
        subscribed_at (None | str):
        raw (bool | float | list[Any] | None | PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1 |
            str):
        is_deleted (bool):
        deleted_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
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
        | PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1
        | str
    )
    fields: (
        bool
        | float
        | list[Any]
        | None
        | PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1
        | str
    )
    subscribed_at: None | str
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1
        | str
    )
    is_deleted: bool
    deleted_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str

    def to_dict(self) -> dict[str, Any]:
        from ..models.put_integration_integration_audience_contacts_id_response_200_fields_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1,
        )
        from ..models.put_integration_integration_audience_contacts_id_response_200_raw_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1,
        )
        from ..models.put_integration_integration_audience_contacts_id_response_200_tags_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1,
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
        if isinstance(
            self.tags, PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1
        ):
            tags = self.tags.to_dict()
        elif isinstance(self.tags, list):
            tags = self.tags

        else:
            tags = self.tags

        fields: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(
            self.fields, PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1
        ):
            fields = self.fields.to_dict()
        elif isinstance(self.fields, list):
            fields = self.fields

        else:
            fields = self.fields

        subscribed_at: None | str
        subscribed_at = self.subscribed_at

        raw: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(
            self.raw, PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1
        ):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "connectionId": connection_id,
                "provider": provider,
                "audienceId": audience_id,
                "externalId": external_id,
                "email": email,
                "status": status,
                "firstName": first_name,
                "lastName": last_name,
                "tags": tags,
                "fields": fields,
                "subscribedAt": subscribed_at,
                "raw": raw,
                "isDeleted": is_deleted,
                "deletedAt": deleted_at,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
                "authorKind": author_kind,
                "authorId": author_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_integration_integration_audience_contacts_id_response_200_fields_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1,
        )
        from ..models.put_integration_integration_audience_contacts_id_response_200_raw_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1,
        )
        from ..models.put_integration_integration_audience_contacts_id_response_200_tags_type_0_type_1 import (
            PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        connection_id = d.pop("connectionId")

        provider = d.pop("provider")

        audience_id = d.pop("audienceId")

        external_id = d.pop("externalId")

        email = d.pop("email")

        status = d.pop("status")

        def _parse_first_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        first_name = _parse_first_name(d.pop("firstName"))

        def _parse_last_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_name = _parse_last_name(d.pop("lastName"))

        def _parse_tags(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                tags_type_0_type_1 = (
                    PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1.from_dict(
                        data
                    )
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
                | PutIntegrationIntegrationAudienceContactsIdResponse200TagsType0Type1
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
            | PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                fields_type_0_type_1 = PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1.from_dict(
                    data
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
                | PutIntegrationIntegrationAudienceContactsIdResponse200FieldsType0Type1
                | str,
                data,
            )

        fields = _parse_fields(d.pop("fields"))

        def _parse_subscribed_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subscribed_at = _parse_subscribed_at(d.pop("subscribedAt"))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1.from_dict(
                        data
                    )
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
                | PutIntegrationIntegrationAudienceContactsIdResponse200RawType0Type1
                | str,
                data,
            )

        raw = _parse_raw(d.pop("raw"))

        is_deleted = d.pop("isDeleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        put_integration_integration_audience_contacts_id_response_200 = cls(
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
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
        )

        return put_integration_integration_audience_contacts_id_response_200
