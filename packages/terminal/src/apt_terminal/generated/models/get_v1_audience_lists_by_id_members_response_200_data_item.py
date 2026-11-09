from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.list_member_delivery_status import ListMemberDeliveryStatus
from ..models.list_member_status import ListMemberStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AudienceListsByIdMembersResponse200DataItem")


@_attrs_define
class GetV1AudienceListsByIdMembersResponse200DataItem:
    """
    Attributes:
        id (str): the list_members row id
        contact_id (str):
        email (None | str):
        name (None | str):
        delivery_status (ListMemberDeliveryStatus):
        bounce_count (int):
        status (ListMemberStatus):
        consent_source_url (None | str):
        consent_at (str):
        unsubscribed_at (None | str): When they LAST unsubscribed. Durable — a later resubscribe never clears it, so a
            currently-subscribed member may carry one.
        resubscribed_at (None | str): When they last signed up again after unsubscribing. Null if they never did.
        unsubscribe_count (int): Opt-out transitions for this membership. A mailbox provider retrying the one-click
            unsubscribe does not increment it; a resubscribe does not reset it.
        emails_sent_count (int):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['member'] | Unset):
    """

    id: str
    contact_id: str
    email: None | str
    name: None | str
    delivery_status: ListMemberDeliveryStatus
    bounce_count: int
    status: ListMemberStatus
    consent_source_url: None | str
    consent_at: str
    unsubscribed_at: None | str
    resubscribed_at: None | str
    unsubscribe_count: int
    emails_sent_count: int
    created: int
    object_: Literal["member"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        contact_id = self.contact_id

        email: None | str
        email = self.email

        name: None | str
        name = self.name

        delivery_status = self.delivery_status.value

        bounce_count = self.bounce_count

        status = self.status.value

        consent_source_url: None | str
        consent_source_url = self.consent_source_url

        consent_at = self.consent_at

        unsubscribed_at: None | str
        unsubscribed_at = self.unsubscribed_at

        resubscribed_at: None | str
        resubscribed_at = self.resubscribed_at

        unsubscribe_count = self.unsubscribe_count

        emails_sent_count = self.emails_sent_count

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "contact_id": contact_id,
                "email": email,
                "name": name,
                "delivery_status": delivery_status,
                "bounce_count": bounce_count,
                "status": status,
                "consent_source_url": consent_source_url,
                "consent_at": consent_at,
                "unsubscribed_at": unsubscribed_at,
                "resubscribed_at": resubscribed_at,
                "unsubscribe_count": unsubscribe_count,
                "emails_sent_count": emails_sent_count,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        contact_id = d.pop("contact_id")

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        def _parse_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        name = _parse_name(d.pop("name"))

        delivery_status = ListMemberDeliveryStatus(d.pop("delivery_status"))

        bounce_count = d.pop("bounce_count")

        status = ListMemberStatus(d.pop("status"))

        def _parse_consent_source_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        consent_source_url = _parse_consent_source_url(d.pop("consent_source_url"))

        consent_at = d.pop("consent_at")

        def _parse_unsubscribed_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        unsubscribed_at = _parse_unsubscribed_at(d.pop("unsubscribed_at"))

        def _parse_resubscribed_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        resubscribed_at = _parse_resubscribed_at(d.pop("resubscribed_at"))

        unsubscribe_count = d.pop("unsubscribe_count")

        emails_sent_count = d.pop("emails_sent_count")

        created = d.pop("created")

        object_ = cast(Literal["member"] | Unset, d.pop("object", UNSET))
        if object_ != "member" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'member', got '{object_}'")

        get_v1_audience_lists_by_id_members_response_200_data_item = cls(
            id=id,
            contact_id=contact_id,
            email=email,
            name=name,
            delivery_status=delivery_status,
            bounce_count=bounce_count,
            status=status,
            consent_source_url=consent_source_url,
            consent_at=consent_at,
            unsubscribed_at=unsubscribed_at,
            resubscribed_at=resubscribed_at,
            unsubscribe_count=unsubscribe_count,
            emails_sent_count=emails_sent_count,
            created=created,
            object_=object_,
        )

        get_v1_audience_lists_by_id_members_response_200_data_item.additional_properties = d
        return get_v1_audience_lists_by_id_members_response_200_data_item

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
