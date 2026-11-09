from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1WebhookEndpointsResponse201")


@_attrs_define
class PostV1WebhookEndpointsResponse201:
    """
    Attributes:
        id (UUID):
        ecosystem_id (str): Ecosystem that owns this endpoint
        owner_kind (str): Kind of principal that owns the endpoint: 'customer', 'organization', 'application', 'persona'
            or 'ecosystem'.
        owner_id (str): Id of the owning principal.
        url (str): HTTPS-only delivery target URL
        event_types (list[str]): Subscribed event types (e.g. job.succeeded, job.failed)
        active (bool): Whether the endpoint receives deliveries
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        secret (str): whsec_-prefixed Standard Webhooks signing secret — returned exactly once. Store it; it cannot be
            retrieved again.
        description (None | str | Unset): Human-readable label
        object_ (Literal['webhook_endpoint'] | Unset):
    """

    id: UUID
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    url: str
    event_types: list[str]
    active: bool
    created: int
    updated: int
    secret: str
    description: None | str | Unset = UNSET
    object_: Literal["webhook_endpoint"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        url = self.url

        event_types = self.event_types

        active = self.active

        created = self.created

        updated = self.updated

        secret = self.secret

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "url": url,
                "event_types": event_types,
                "active": active,
                "created": created,
                "updated": updated,
                "secret": secret,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        url = d.pop("url")

        event_types = cast(list[str], d.pop("event_types"))

        active = d.pop("active")

        created = d.pop("created")

        updated = d.pop("updated")

        secret = d.pop("secret")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        object_ = cast(Literal["webhook_endpoint"] | Unset, d.pop("object", UNSET))
        if object_ != "webhook_endpoint" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'webhook_endpoint', got '{object_}'")

        post_v1_webhook_endpoints_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            url=url,
            event_types=event_types,
            active=active,
            created=created,
            updated=updated,
            secret=secret,
            description=description,
            object_=object_,
        )

        post_v1_webhook_endpoints_response_201.additional_properties = d
        return post_v1_webhook_endpoints_response_201

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
