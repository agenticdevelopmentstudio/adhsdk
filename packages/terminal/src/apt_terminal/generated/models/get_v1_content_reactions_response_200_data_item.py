from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.reaction_author_kind import ReactionAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ContentReactionsResponse200DataItem")


@_attrs_define
class GetV1ContentReactionsResponse200DataItem:
    """
    Attributes:
        id (str):
        customer_id (str): The customer who reacted, or '' when the author is not a customer. Kept for clients built
            before the pairs; read authorKind/authorId instead.
        ecosystem_id (str):
        target_kind (str):
        target_id (str):
        emoji (str):
        created (int): Unix timestamp, in seconds.
        owner_kind (str | Unset): Kind of principal that owns the reaction (the ecosystem): 'customer', 'organization',
            'application', 'persona' or 'ecosystem'.
        owner_id (str | Unset): Id of the owning principal.
        author_kind (ReactionAuthorKind | Unset): Kind of principal that reacted; null when nobody did (a storage
            token).
        author_id (None | str | Unset): Id of that principal.
        deleted_at (None | str | Unset):
        object_ (Literal['content.reaction'] | Unset):
    """

    id: str
    customer_id: str
    ecosystem_id: str
    target_kind: str
    target_id: str
    emoji: str
    created: int
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    author_kind: ReactionAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["content.reaction"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        target_kind = self.target_kind

        target_id = self.target_id

        emoji = self.emoji

        created = self.created

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

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
                "customer_id": customer_id,
                "ecosystem_id": ecosystem_id,
                "target_kind": target_kind,
                "target_id": target_id,
                "emoji": emoji,
                "created": created,
            }
        )
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customer_id")

        ecosystem_id = d.pop("ecosystem_id")

        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        emoji = d.pop("emoji")

        created = d.pop("created")

        owner_kind = d.pop("owner_kind", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ReactionAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ReactionAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["content.reaction"] | Unset, d.pop("object", UNSET))
        if object_ != "content.reaction" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.reaction', got '{object_}'")

        get_v1_content_reactions_response_200_data_item = cls(
            id=id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
            target_kind=target_kind,
            target_id=target_id,
            emoji=emoji,
            created=created,
            owner_kind=owner_kind,
            owner_id=owner_id,
            author_kind=author_kind,
            author_id=author_id,
            deleted_at=deleted_at,
            object_=object_,
        )

        get_v1_content_reactions_response_200_data_item.additional_properties = d
        return get_v1_content_reactions_response_200_data_item

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
