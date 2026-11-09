from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentPollVotesResponse200")


@_attrs_define
class PostV1ContentPollVotesResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str): The customer who owns the vote, or '' when the owner is not a customer. Kept for clients
            built before the pairs; read ownerKind/ownerId instead.
        owner_kind (str): Kind of principal that owns the vote: 'customer', 'organization', 'application', 'persona' or
            'ecosystem'.
        owner_id (str): Id of the owning principal.
        option_id (str):
        created (int): Unix timestamp, in seconds.
        deleted_at (None | str | Unset):
        object_ (Literal['content.poll_vote'] | Unset):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    owner_kind: str
    owner_id: str
    option_id: str
    created: int
    deleted_at: None | str | Unset = UNSET
    object_: Literal["content.poll_vote"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        option_id = self.option_id

        created = self.created

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "customer_id": customer_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "option_id": option_id,
                "created": created,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        customer_id = d.pop("customer_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        option_id = d.pop("option_id")

        created = d.pop("created")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["content.poll_vote"] | Unset, d.pop("object", UNSET))
        if object_ != "content.poll_vote" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.poll_vote', got '{object_}'")

        post_v1_content_poll_votes_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            option_id=option_id,
            created=created,
            deleted_at=deleted_at,
            object_=object_,
        )

        post_v1_content_poll_votes_response_200.additional_properties = d
        return post_v1_content_poll_votes_response_200

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
