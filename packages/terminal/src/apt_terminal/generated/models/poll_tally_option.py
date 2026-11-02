from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PollTallyOption")


@_attrs_define
class PollTallyOption:
    """
    Attributes:
        option_id (str):
        text (str):
        sort_order (int):
        votes (int):
    """

    option_id: str
    text: str
    sort_order: int
    votes: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        option_id = self.option_id

        text = self.text

        sort_order = self.sort_order

        votes = self.votes

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "optionId": option_id,
                "text": text,
                "sortOrder": sort_order,
                "votes": votes,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        option_id = d.pop("optionId")

        text = d.pop("text")

        sort_order = d.pop("sortOrder")

        votes = d.pop("votes")

        poll_tally_option = cls(
            option_id=option_id,
            text=text,
            sort_order=sort_order,
            votes=votes,
        )

        poll_tally_option.additional_properties = d
        return poll_tally_option

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
