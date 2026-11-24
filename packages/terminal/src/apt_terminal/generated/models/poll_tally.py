from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.poll_tally_option import PollTallyOption


T = TypeVar("T", bound="PollTally")


@_attrs_define
class PollTally:
    """
    Attributes:
        poll_id (str):
        options (list[PollTallyOption]):
        my_option_ids (list[str]):
    """

    poll_id: str
    options: list[PollTallyOption]
    my_option_ids: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        poll_id = self.poll_id

        options = []
        for options_item_data in self.options:
            options_item = options_item_data.to_dict()
            options.append(options_item)

        my_option_ids = self.my_option_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "poll_id": poll_id,
                "options": options,
                "my_option_ids": my_option_ids,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.poll_tally_option import PollTallyOption

        d = dict(src_dict)
        poll_id = d.pop("poll_id")

        options = []
        _options = d.pop("options")
        for options_item_data in _options:
            options_item = PollTallyOption.from_dict(options_item_data)

            options.append(options_item)

        my_option_ids = cast(list[str], d.pop("my_option_ids"))

        poll_tally = cls(
            poll_id=poll_id,
            options=options,
            my_option_ids=my_option_ids,
        )

        poll_tally.additional_properties = d
        return poll_tally

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
