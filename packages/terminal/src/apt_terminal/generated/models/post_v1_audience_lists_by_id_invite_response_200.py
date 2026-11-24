from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AudienceListsByIdInviteResponse200")


@_attrs_define
class PostV1AudienceListsByIdInviteResponse200:
    """
    Attributes:
        created (int): new auth.pending_users rows created from this list
        skipped (int): members already pending/invited, or undeliverable, so left untouched
        object_ (Literal['audience.list'] | Unset):
    """

    created: int
    skipped: int
    object_: Literal["audience.list"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        created = self.created

        skipped = self.skipped

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "created": created,
                "skipped": skipped,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        created = d.pop("created")

        skipped = d.pop("skipped")

        object_ = cast(Literal["audience.list"] | Unset, d.pop("object", UNSET))
        if object_ != "audience.list" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'audience.list', got '{object_}'")

        post_v1_audience_lists_by_id_invite_response_200 = cls(
            created=created,
            skipped=skipped,
            object_=object_,
        )

        post_v1_audience_lists_by_id_invite_response_200.additional_properties = d
        return post_v1_audience_lists_by_id_invite_response_200

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
