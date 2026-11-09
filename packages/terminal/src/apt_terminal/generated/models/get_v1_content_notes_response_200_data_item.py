from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ContentNotesResponse200DataItem")


@_attrs_define
class GetV1ContentNotesResponse200DataItem:
    """
    Attributes:
        id (str):
        content (str):
        title (str): Derived from the doc’s first line.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['content.note'] | Unset):
    """

    id: str
    content: str
    title: str
    created: int
    updated: int
    object_: Literal["content.note"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        content = self.content

        title = self.title

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "content": content,
                "title": title,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        content = d.pop("content")

        title = d.pop("title")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["content.note"] | Unset, d.pop("object", UNSET))
        if object_ != "content.note" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.note', got '{object_}'")

        get_v1_content_notes_response_200_data_item = cls(
            id=id,
            content=content,
            title=title,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_content_notes_response_200_data_item.additional_properties = d
        return get_v1_content_notes_response_200_data_item

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
