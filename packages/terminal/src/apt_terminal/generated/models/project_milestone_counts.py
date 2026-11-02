from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ProjectMilestoneCounts")


@_attrs_define
class ProjectMilestoneCounts:
    """the milestone’s live cards counted by status CATEGORY, every category present (0 included) so a client never has to
    distinguish an absent key from an empty column. DERIVED on every read, never stored. The API deliberately reports no
    percentage: whether a `canceled` card belongs in the denominator is a product question, and answering it here would
    freeze one answer into the wire format.

        Attributes:
            backlog (int):
            todo (int):
            in_progress (int):
            done (int):
            canceled (int):
    """

    backlog: int
    todo: int
    in_progress: int
    done: int
    canceled: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        backlog = self.backlog

        todo = self.todo

        in_progress = self.in_progress

        done = self.done

        canceled = self.canceled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "backlog": backlog,
                "todo": todo,
                "in_progress": in_progress,
                "done": done,
                "canceled": canceled,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        backlog = d.pop("backlog")

        todo = d.pop("todo")

        in_progress = d.pop("in_progress")

        done = d.pop("done")

        canceled = d.pop("canceled")

        project_milestone_counts = cls(
            backlog=backlog,
            todo=todo,
            in_progress=in_progress,
            done=done,
            canceled=canceled,
        )

        project_milestone_counts.additional_properties = d
        return project_milestone_counts

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
