from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_audience_contacts_by_id_body_fields_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1,
    )
    from ..models.post_v1_integrations_audience_contacts_by_id_body_raw_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1,
    )
    from ..models.post_v1_integrations_audience_contacts_by_id_body_tags_type_0_type_1 import (
        PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1,
    )


T = TypeVar("T", bound="PostV1IntegrationsAudienceContactsByIdBody")


@_attrs_define
class PostV1IntegrationsAudienceContactsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        connection_id (str | Unset):
        provider (str | Unset):
        audience_id (str | Unset):
        external_id (str | Unset):
        email (str | Unset):
        status (str | Unset):
        first_name (None | str | Unset):
        last_name (None | str | Unset):
        tags (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1 | str | Unset):
        fields (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1 | str |
            Unset):
        subscribed_at (None | str | Unset):
        raw (bool | float | list[Any] | None | PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    connection_id: str | Unset = UNSET
    provider: str | Unset = UNSET
    audience_id: str | Unset = UNSET
    external_id: str | Unset = UNSET
    email: str | Unset = UNSET
    status: str | Unset = UNSET
    first_name: None | str | Unset = UNSET
    last_name: None | str | Unset = UNSET
    tags: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1
        | str
        | Unset
    ) = UNSET
    fields: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1
        | str
        | Unset
    ) = UNSET
    subscribed_at: None | str | Unset = UNSET
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1
        | str
        | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_integrations_audience_contacts_by_id_body_fields_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_body_raw_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_body_tags_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1,
        )

        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        provider = self.provider

        audience_id = self.audience_id

        external_id = self.external_id

        email = self.email

        status = self.status

        first_name: None | str | Unset
        if isinstance(self.first_name, Unset):
            first_name = UNSET
        else:
            first_name = self.first_name

        last_name: None | str | Unset
        if isinstance(self.last_name, Unset):
            last_name = UNSET
        else:
            last_name = self.last_name

        tags: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.tags, Unset):
            tags = UNSET
        elif isinstance(self.tags, PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1):
            tags = self.tags.to_dict()
        elif isinstance(self.tags, list):
            tags = self.tags

        else:
            tags = self.tags

        fields: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.fields, Unset):
            fields = UNSET
        elif isinstance(self.fields, PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1):
            fields = self.fields.to_dict()
        elif isinstance(self.fields, list):
            fields = self.fields

        else:
            fields = self.fields

        subscribed_at: None | str | Unset
        if isinstance(self.subscribed_at, Unset):
            subscribed_at = UNSET
        else:
            subscribed_at = self.subscribed_at

        raw: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.raw, Unset):
            raw = UNSET
        elif isinstance(self.raw, PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if provider is not UNSET:
            field_dict["provider"] = provider
        if audience_id is not UNSET:
            field_dict["audience_id"] = audience_id
        if external_id is not UNSET:
            field_dict["external_id"] = external_id
        if email is not UNSET:
            field_dict["email"] = email
        if status is not UNSET:
            field_dict["status"] = status
        if first_name is not UNSET:
            field_dict["first_name"] = first_name
        if last_name is not UNSET:
            field_dict["last_name"] = last_name
        if tags is not UNSET:
            field_dict["tags"] = tags
        if fields is not UNSET:
            field_dict["fields"] = fields
        if subscribed_at is not UNSET:
            field_dict["subscribed_at"] = subscribed_at
        if raw is not UNSET:
            field_dict["raw"] = raw

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_audience_contacts_by_id_body_fields_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_body_raw_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1,
        )
        from ..models.post_v1_integrations_audience_contacts_by_id_body_tags_type_0_type_1 import (
            PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        connection_id = d.pop("connection_id", UNSET)

        provider = d.pop("provider", UNSET)

        audience_id = d.pop("audience_id", UNSET)

        external_id = d.pop("external_id", UNSET)

        email = d.pop("email", UNSET)

        status = d.pop("status", UNSET)

        def _parse_first_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        first_name = _parse_first_name(d.pop("first_name", UNSET))

        def _parse_last_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_name = _parse_last_name(d.pop("last_name", UNSET))

        def _parse_tags(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                tags_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1.from_dict(data)
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
                | PostV1IntegrationsAudienceContactsByIdBodyTagsType0Type1
                | str
                | Unset,
                data,
            )

        tags = _parse_tags(d.pop("tags", UNSET))

        def _parse_fields(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                fields_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1.from_dict(data)
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
                | PostV1IntegrationsAudienceContactsByIdBodyFieldsType0Type1
                | str
                | Unset,
                data,
            )

        fields = _parse_fields(d.pop("fields", UNSET))

        def _parse_subscribed_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subscribed_at = _parse_subscribed_at(d.pop("subscribed_at", UNSET))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1.from_dict(data)
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
                | PostV1IntegrationsAudienceContactsByIdBodyRawType0Type1
                | str
                | Unset,
                data,
            )

        raw = _parse_raw(d.pop("raw", UNSET))

        post_v1_integrations_audience_contacts_by_id_body = cls(
            ecosystem_id=ecosystem_id,
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
        )

        return post_v1_integrations_audience_contacts_by_id_body
