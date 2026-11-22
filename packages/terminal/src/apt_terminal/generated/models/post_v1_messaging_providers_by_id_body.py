from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_messaging_providers_by_id_body_fields import (
        PostV1MessagingProvidersByIdBodyFields,
    )


T = TypeVar("T", bound="PostV1MessagingProvidersByIdBody")


@_attrs_define
class PostV1MessagingProvidersByIdBody:
    """
    Attributes:
        name (str | Unset): Instance name
        fields (PostV1MessagingProvidersByIdBodyFields | Unset): The provider's config fields by key: postmark
            serverToken, fromEmail, …; twilio accountSid, authToken, fromNumber. An empty string or null clears an optional
            field.
        enabled (bool | Unset): false pauses the provider
    """

    name: str | Unset = UNSET
    fields: PostV1MessagingProvidersByIdBodyFields | Unset = UNSET
    enabled: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        fields: dict[str, Any] | Unset = UNSET
        if not isinstance(self.fields, Unset):
            fields = self.fields.to_dict()

        enabled = self.enabled

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if fields is not UNSET:
            field_dict["fields"] = fields
        if enabled is not UNSET:
            field_dict["enabled"] = enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_messaging_providers_by_id_body_fields import (
            PostV1MessagingProvidersByIdBodyFields,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        _fields = d.pop("fields", UNSET)
        fields: PostV1MessagingProvidersByIdBodyFields | Unset
        if isinstance(_fields, Unset):
            fields = UNSET
        else:
            fields = PostV1MessagingProvidersByIdBodyFields.from_dict(_fields)

        enabled = d.pop("enabled", UNSET)

        post_v1_messaging_providers_by_id_body = cls(
            name=name,
            fields=fields,
            enabled=enabled,
        )

        return post_v1_messaging_providers_by_id_body
