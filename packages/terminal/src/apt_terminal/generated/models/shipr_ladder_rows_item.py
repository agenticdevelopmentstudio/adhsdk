from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ShiprLadderRowsItem")


@_attrs_define
class ShiprLadderRowsItem:
    """
    Attributes:
        sha (str | Unset):
        when (str | Unset):
        subject (str | Unset):
        marks (list[str] | Unset):
        settled (bool | Unset):
    """

    sha: str | Unset = UNSET
    when: str | Unset = UNSET
    subject: str | Unset = UNSET
    marks: list[str] | Unset = UNSET
    settled: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sha = self.sha

        when = self.when

        subject = self.subject

        marks: list[str] | Unset = UNSET
        if not isinstance(self.marks, Unset):
            marks = self.marks

        settled = self.settled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if sha is not UNSET:
            field_dict["sha"] = sha
        if when is not UNSET:
            field_dict["when"] = when
        if subject is not UNSET:
            field_dict["subject"] = subject
        if marks is not UNSET:
            field_dict["marks"] = marks
        if settled is not UNSET:
            field_dict["settled"] = settled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        sha = d.pop("sha", UNSET)

        when = d.pop("when", UNSET)

        subject = d.pop("subject", UNSET)

        marks = cast(list[str], d.pop("marks", UNSET))

        settled = d.pop("settled", UNSET)

        shipr_ladder_rows_item = cls(
            sha=sha,
            when=when,
            subject=subject,
            marks=marks,
            settled=settled,
        )

        shipr_ladder_rows_item.additional_properties = d
        return shipr_ladder_rows_item

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
